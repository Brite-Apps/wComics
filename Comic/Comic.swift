//
//  Comic.swift
//  wComics
//
//  Created by Nikita Denin on 27.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import Foundation
import UIKit
import PDFKit

enum ArchType {
	case zip, rar, pdf, none
}

class Comic: Comparable, @unchecked Sendable {
	static func < (lhs: Comic, rhs: Comic) -> Bool {
		return lhs.file < rhs.file
	}
	
	static func == (lhs: Comic, rhs: Comic) -> Bool {
		return (lhs.file as NSString).resolvingSymlinksInPath == (rhs.file as NSString).resolvingSymlinksInPath
	}
	
	let file: String
	let title: String
	private(set) var numberOfPages = 0
	
	private var zipArchive: MiniZip?
	private var rarArchive: UnRAR?
	private var pdfDoc: PDFDocument?
	private var filesList = [String]()
	private var archType = ArchType.none
	
	nonisolated(unsafe) private static let imageCache = NSCache<NSString, UIImage>()
	private static let validExtensions = ["jpg", "jpeg", "png", "gif", "tiff", "tif"]
	
	init?(file: String) {
		let fileURL = URL(fileURLWithPath: file)
		guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
		
		self.file = file
		self.title = fileURL.deletingPathExtension().lastPathComponent

		if let zipArchive = MiniZip(archiveAtPath: file) {
			self.zipArchive = zipArchive
			zipArchive.skipInvisibleFiles = true
			
			if let files = zipArchive.retrieveFileList() as? [String] {
				let filteredFiles = files.filter { file in
					let ext = (file as NSString).pathExtension.lowercased()
					return Self.validExtensions.contains(ext)
				}
				
				if !filteredFiles.isEmpty {
					filesList = filteredFiles.sorted()
					numberOfPages = filesList.count
					archType = .zip
				}
			}
		}
		
		if archType == .none {
			if let rarArchive = UnRAR(archiveAtPath: file) {
				self.rarArchive = rarArchive
				rarArchive.skipInvisibleFiles = true

				if let files = rarArchive.retrieveFileList() as? [String] {
					let filteredFiles = files.filter { file in
						let ext = (file as NSString).pathExtension.lowercased()
						return Self.validExtensions.contains(ext)
					}
					
					if !filteredFiles.isEmpty {
						filesList = filteredFiles.sorted()
						numberOfPages = filesList.count
						archType = .rar
					}
				}
			}
		}
		
		if archType == .none {
			if let pdfDoc = PDFDocument(url: fileURL) {
				self.pdfDoc = pdfDoc
				archType = .pdf
				numberOfPages = pdfDoc.pageCount
			}
		}
		
		if archType == .none {
			return nil
		}
	}

	private let extractionQueue = DispatchQueue(label: "com.wcomics.extraction")
	
	func imageAtIndex(_ index: Int, screenSize: CGSize, scale: CGFloat) -> UIImage? {
		guard index >= 0, index < numberOfPages else { return nil }
		
		let cacheKey = "\(file)_\(index)_\(Int(screenSize.width))x\(Int(screenSize.height))@\(Int(scale))x" as NSString
		if let cachedImage = Self.imageCache.object(forKey: cacheKey) {
			return cachedImage
		}
		
		var img: UIImage? = nil
		
		switch archType {
			case .zip, .rar:
				extractionQueue.sync {
					let archive: ArchiveProvider? = archType == .zip ? zipArchive : rarArchive
					guard let archive = archive else { return }
					
					let tempFileName = ProcessInfo.processInfo.globallyUniqueString
					let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(tempFileName)
					
					if archive.extractFile(filesList[index], toPath: tempPath) {
						if let data = try? Data(contentsOf: URL(fileURLWithPath: tempPath)) {
							img = UIImage(data: data)
						}
						try? FileManager.default.removeItem(atPath: tempPath)
					}
				}
				
			case .pdf:
				guard let pdfDoc = pdfDoc, let page = pdfDoc.page(at: index) else { return nil }
				
				let pageRect = page.bounds(for: .cropBox)
				let maxSide = max(screenSize.width, screenSize.height) * scale
				let scaleFactor = maxSide / max(pageRect.width, pageRect.height)
				let thumbnailSize = CGSize(width: pageRect.width * scaleFactor, height: pageRect.height * scaleFactor)
				
				img = page.thumbnail(of: thumbnailSize, for: .cropBox)
				
			case .none:
				break
		}
		
		if let img = img {
			Self.imageCache.setObject(img, forKey: cacheKey)
		}
		
		return img
	}
	
	func somewhereInSubdir(of dir: String) -> Bool {
		let fileURL = URL(fileURLWithPath: file).resolvingSymlinksInPath()
		let dirURL = URL(fileURLWithPath: dir).resolvingSymlinksInPath()
		
		return fileURL.path.hasPrefix(dirURL.path)
	}
	
	static func createCoverImage(for path: String) async -> (UIImage, String)? {
		let pathURL = URL(fileURLWithPath: path)
		let coverPath = (COVERSPATH as NSString).appendingPathComponent("\(pathURL.lastPathComponent)_wcomics_cover_file")
		
		if let data = try? Data(contentsOf: URL(fileURLWithPath: coverPath)), let image = UIImage(data: data) {
			return (image, coverPath)
		}

		var coverImage: UIImage? = nil

		if let archive = ArchiveWrapper(archiveAtPath: path) {
			archive.skipInvisibleFiles = true
			
			if let files = archive.retrieveFileList()?.sorted() {
				for file in files {
					let ext = (file as NSString).pathExtension.lowercased()
					if Self.validExtensions.contains(ext) {
						let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
						
						if archive.extractFile(file, toPath: tempPath) {
							if let d = try? Data(contentsOf: URL(fileURLWithPath: tempPath)), let img = UIImage(data: d) {
								coverImage = img
							}
							try? FileManager.default.removeItem(atPath: tempPath)
						}
						
						if coverImage != nil { break }
					}
				}
			}
		}
		else if let pdfDoc = PDFDocument(url: pathURL), let page = pdfDoc.page(at: 0) {
			coverImage = page.thumbnail(of: CGSize(width: 300, height: 400), for: .cropBox)
		}
		
		guard let img = coverImage else { return nil }
		
		let targetSize = CGSize(width: 120, height: 160)
		let renderer = UIGraphicsImageRenderer(size: targetSize)
		let scaledImage = renderer.image { context in
			UIColor.white.setFill()
			context.fill(CGRect(origin: .zero, size: targetSize))
			
			let aspect = img.size.width / img.size.height
			var drawSize = targetSize
			if aspect > targetSize.width / targetSize.height {
				drawSize.height = targetSize.width / aspect
			}
			else {
				drawSize.width = targetSize.height * aspect
			}
			
			let drawRect = CGRect(x: (targetSize.width - drawSize.width) / 2,
								 y: (targetSize.height - drawSize.height) / 2,
								 width: drawSize.width,
								 height: drawSize.height)
			img.draw(in: drawRect)
		}
		
		if let data = scaledImage.jpegData(compressionQuality: 0.8) {
			try? FileManager.default.createDirectory(at: URL(fileURLWithPath: COVERSPATH), withIntermediateDirectories: true)
			try? data.write(to: URL(fileURLWithPath: coverPath))
			return (scaledImage, coverPath)
		}
		
		return nil
	}
}

private protocol ArchiveProvider {
	func extractFile(_ inPath: String, toPath: String) -> Bool
}

extension MiniZip: ArchiveProvider {}
extension UnRAR: ArchiveProvider {}

private class ArchiveWrapper: ArchiveProvider {
	private let zipArchive: MiniZip?
	private let rarArchive: UnRAR?
	
	init?(archiveAtPath path: String) {
		zipArchive = MiniZip(archiveAtPath: path)
		rarArchive = UnRAR(archiveAtPath: path)
		
		if zipArchive == nil && rarArchive == nil {
			return nil
		}
	}
	
	var skipInvisibleFiles: Bool {
		set {
			zipArchive?.skipInvisibleFiles = newValue
			rarArchive?.skipInvisibleFiles = newValue
		}
		get {
			zipArchive?.skipInvisibleFiles ?? rarArchive?.skipInvisibleFiles ?? false
		}
	}
	
	func retrieveFileList() -> [String]? {
		return (zipArchive?.retrieveFileList() as? [String]) ?? (rarArchive?.retrieveFileList() as? [String])
	}
	
	func extractFile(_ inPath: String, toPath: String) -> Bool {
		return zipArchive?.extractFile(inPath, toPath: toPath) ?? rarArchive?.extractFile(inPath, toPath: toPath) ?? false
	}
}
