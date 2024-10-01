
//
//  Comic.swift
//  wComics
//
//  Created by Nikita Denin on 27.09.24.
//  Copyright © 2024 Nik S Dyonin. All rights reserved.
//

import Foundation
import UIKit

enum ArchType {
	case zip, rar, pdf, none
}

class Comic: Comparable {
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
	private var pdfDoc: CGPDFDocument?
	private var filesList = [String]()
	private var archType = ArchType.none
	
	private static let validExtensions = ["jpg", "jpeg", "png", "gif", "tiff", "tif"]
	
	init?(file: String) {
		guard FileManager.default.fileExists(atPath: file) else { return nil }
		
		self.file = file
		self.title = ((file as NSString).lastPathComponent as NSString).deletingPathExtension

		if let zipArchive = MiniZip(archiveAtPath: file) {
			self.zipArchive = zipArchive
			
			zipArchive.skipInvisibleFiles = true
			
			if let files = zipArchive.retrieveFileList()?.compactMap({ file in
				if let file = file as? NSString {
					let ext = file.pathExtension.lowercased()
					
					if Self.validExtensions.contains(ext) {
						return file as String
					}
				}
				
				return nil
			}) {
				filesList.append(contentsOf: files)
				numberOfPages = filesList.count
				archType = .zip
			}
		}
		
		if archType != .zip {
			if let rarArchive = UnRAR(archiveAtPath: file) {
				self.rarArchive = rarArchive
				
				rarArchive.skipInvisibleFiles = true

				if let files = rarArchive.retrieveFileList()?.compactMap({ file in
					if let file = file as? NSString {
						let ext = file.pathExtension.lowercased()
						
						if Self.validExtensions.contains(ext) {
							return file as String
						}
					}
					
					return nil
				}) {
					filesList.append(contentsOf: files)
					numberOfPages = filesList.count
					archType = .rar
				}
			}
		}
		
		if archType == .none {
			if let pdfUrl = CFURLCreateWithFileSystemPath(nil, (file as NSString) as CFString, .cfurlposixPathStyle, false) {
				if let pdfDoc = CGPDFDocument(pdfUrl) {
					self.pdfDoc = pdfDoc
					archType = .pdf
					numberOfPages = pdfDoc.numberOfPages
				}
				
			}
		}
		
		if archType == .none {
			return nil
		}
		
		filesList.sort()
	}

	func imageAtIndex(_ index: Int, screenSize: CGSize) -> UIImage? {
		guard index >= 0, index < numberOfPages else { return nil }
		
		var img: UIImage? = nil
		
		switch archType {
			case .zip:
				guard let zipArchive = zipArchive else { return nil }
				
				let temp = (NSTemporaryDirectory() as NSString).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
				
				if zipArchive.extractFile(filesList[index], toPath: temp) {
					if let data = try? Data(contentsOf: URL(fileURLWithPath: temp)) {
						img = UIImage(data: data)
					}
				}
				
				try? FileManager.default.removeItem(atPath: temp)
			case .rar:
				guard let rarArchive = rarArchive else { return nil }
				let temp = (NSTemporaryDirectory() as NSString).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
				
				if rarArchive.extractFile(filesList[index], toPath: temp) {
					if let data = try? Data(contentsOf: URL(fileURLWithPath: temp)) {
						img = UIImage(data: data)
					}
				}
				
				try? FileManager.default.removeItem(atPath: temp)
			case .pdf:
				guard let pdfDoc = pdfDoc else { return nil }

				if let pdfPage = pdfDoc.page(at: index + 1) {
					let pageRect = CGRectIntegral(pdfPage.getBoxRect(.cropBox))
					var size = pageRect.size;
					let maxSide = max(screenSize.width, screenSize.height)
					
					if size.width < maxSide {
						let c = maxSide / size.width
						size.width = maxSide
						size.height = floor(size.height * c)
					}
					
					if size.height < maxSide {
						let c = maxSide / size.height
						size.height = maxSide
						size.width = floor(size.width * c)
					}
					
					UIGraphicsBeginImageContextWithOptions(size, true, 0)
					
					if let ctx = UIGraphicsGetCurrentContext() {
						ctx.scaleBy(x: 1, y: -1)
						ctx.translateBy(x: 0, y: -size.height)
						
						if let cg = UIColor.white.cgColor.components {
							ctx.setFillColor(cg)
							ctx.fill(CGRectMake(0, 0, size.width, size.height))
						}
						
						let mediaRect = pdfPage.getBoxRect(.cropBox)

						ctx.scaleBy(x: size.width / mediaRect.size.width, y: size.height / mediaRect.size.height)
						ctx.translateBy(x: -mediaRect.origin.x, y: -mediaRect.origin.y)
						
						ctx.drawPDFPage(pdfPage)
						
						img = UIGraphicsGetImageFromCurrentImageContext()
					}
					
					UIGraphicsEndImageContext();
				}
			case .none:
				break
		}
		
		return img
	}
	
	func somewhereInSubdir(of dir: String) -> Bool {
		guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return false }

		for item in files {
			var isDir: ObjCBool = false
			let fullPath = (dir as NSString).appendingPathComponent(item)
			
			if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir) {
				if isDir.boolValue {
					if somewhereInSubdir(of: fullPath) {
						return true
					}
				}
				else {
					if (self.file as NSString).resolvingSymlinksInPath == (fullPath as NSString).resolvingSymlinksInPath {
						return true
					}
				}
			}
		}
		
		return false
	}
	
	static func createCoverImage(for path: String) async -> (UIImage, String)? {
		if let archive = ArchiveWrapper(archiveAtPath: path) {
			archive.skipInvisibleFiles = true
			
			guard let files = archive.retrieveFileList()?.sorted() else { return nil }
			
			for file in files {
				let ext = (file as NSString).pathExtension.lowercased()
				
				if Self.validExtensions.contains(ext) {
					let temp = (NSTemporaryDirectory() as NSString).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
					
					if archive.extractFile(file, toPath: temp) {
						guard let d = try? Data(contentsOf: URL(fileURLWithPath: file)) else { continue }
						guard let cover = UIImage(data: d) else { continue }
						
						if cover.size.width == 0 {
							continue
						}
						
						var c = 31.0 / cover.size.width
						var newSize = CGSize(width: cover.size.width * c, height: cover.size.height * c)
						
						if newSize.width > 31.0 {
							c = 31.0 / newSize.width
							newSize.width = 31.0
							newSize.height *= c
						}
						
						if newSize.height > 40.0 {
							c = 40.0 / newSize.height
							newSize.height = 40.0
							newSize.width *= c
						}
						
						UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
						
						guard let context = UIGraphicsGetCurrentContext() else { continue }
						
						if let cg = UIColor.white.cgColor.components {
							context.setFillColor(cg)
							context.fill(CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
						}
						
						cover.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
						
						let newImage = UIGraphicsGetImageFromCurrentImageContext()

						UIGraphicsEndImageContext()

						if let newImage = newImage {
							if let newCoverData = newImage.jpegData(compressionQuality: 0.8) {
								let coverFile = "\(DOCPATH)/covers/\((path as NSString).lastPathComponent)_wcomics_cover_file"
								try? newCoverData.write(to: URL(fileURLWithPath: coverFile))
								return (newImage, coverFile)
							}
						}
					}
				}
			}
		}
		else {
			guard let pdfURL = CFURLCreateWithFileSystemPath(nil, (path as NSString) as CFString, .cfurlposixPathStyle, false) else { return nil }
			guard let pdfDoc = CGPDFDocument(pdfURL) else { return nil }
			guard let pdfPage = pdfDoc.page(at: 1) else { return nil }
			let pageRect = CGRectIntegral(pdfPage.getBoxRect(.cropBox))
			let size = pageRect.size
			var c = 31.0 / size.width
			var newSize = CGSize(width: size.width * c, height: size.height * c)
			
			if newSize.width > 31.0 {
				c = 31.0 / newSize.width
				newSize.width = 31.0
				newSize.height *= c
			}
			
			if newSize.height > 40.0 {
				c = 40.0 / newSize.height
				newSize.height = 40.0
				newSize.width *= c
			}
			
			UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
			
			guard let context = UIGraphicsGetCurrentContext() else { return nil }
			
			let bounds = context.boundingBoxOfClipPath
			context.translateBy(x: 0, y: bounds.size.height)
			context.scaleBy(x: 1.0, y: -1.0)
			
			if let cg = UIColor.white.cgColor.components {
				context.setFillColor(cg)
				context.fill(CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
			}
			
			context.saveGState()
			
			let transformRect = CGRectMake(0, 0, newSize.width, newSize.height)
			let pdfTransform = pdfPage.getDrawingTransform(.cropBox, rect: transformRect, rotate: 0, preserveAspectRatio: true)
			
			context.concatenate(pdfTransform)
			
			context.drawPDFPage(pdfPage)
			
			context.restoreGState()
			
			let newImage = UIGraphicsGetImageFromCurrentImageContext()
			
			UIGraphicsEndImageContext()
			
			if let newImage = newImage {
				if let newCoverData = newImage.jpegData(compressionQuality: 0.8) {
					let coverFile = "\(DOCPATH)/covers/\((path as NSString).lastPathComponent)_wcomics_cover_file"
					try? newCoverData.write(to: URL(fileURLWithPath: coverFile))
					return (newImage, coverFile)
				}
			}
		}
		
		return nil
	}
	
	private class ArchiveWrapper {
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
			return zipArchive?.retrieveFileList() as? [String] ?? rarArchive?.retrieveFileList() as? [String]
		}
		
		func extractFile(_ inPath: String, toPath: String) -> Bool {
			return zipArchive?.extractFile(inPath, toPath: toPath) ?? rarArchive?.extractFile(inPath, toPath: toPath) ?? false
		}
	}
	
	deinit {
		filesList.removeAll()
		zipArchive = nil
		rarArchive = nil
		pdfDoc = nil
	}
}
