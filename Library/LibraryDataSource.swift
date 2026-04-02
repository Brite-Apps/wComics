//
//  LibraryDataSource.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

final class LibraryDataSource: @unchecked Sendable {
	static let instance = LibraryDataSource()
	static let libraryUpdatedNotification = Notification.Name("LibraryUpdated")
	private(set) var library = [ComicItem]()

	private init() {
		// singleton stub
	}

	private static func processItem(path: String, isDirectory: Bool, rootItems: inout [ComicItem], parent: ComicItem?) {
		if !isDirectory && !Comic.isSupportedFile(at: path) {
			return
		}

		let item = ComicItem(path: path, isDir: isDirectory)
		
		if let parent = parent {
			parent.children.append(item)
		}
		else {
			rootItems.append(item)
		}
		
		if isDirectory {
			if let itemsList = try? FileManager.default.contentsOfDirectory(atPath: path), !itemsList.isEmpty {
				for itemName in itemsList {
					let p = (path as NSString).appendingPathComponent(itemName)
					var isDir: ObjCBool = false
					
					if FileManager.default.fileExists(atPath: p, isDirectory: &isDir) {
						processItem(path: p, isDirectory: isDir.boolValue, rootItems: &rootItems, parent: item)
					}
				}
			}
		}
	}
	
	private static func sort(items: inout [ComicItem]) {
		var dirs = [ComicItem]()
		var comics = [ComicItem]()
		
		for item in items {
			if item.isDir {
				sort(items: &item.children)
				dirs.append(item)
			}
			else {
				comics.append(item)
			}
		}
		
		items.removeAll()

		dirs.sort()
		comics.sort()
		
		items.append(contentsOf: dirs)
		items.append(contentsOf: comics)
	}
	
	func updateLibrary(rootPath: String) async {
		var updatedLibrary = [ComicItem]()
		
		if let itemsList = try? FileManager.default.contentsOfDirectory(atPath: rootPath), !itemsList.isEmpty {
			for itemName in itemsList {
				guard itemName != "covers" else { continue }
				guard !itemName.hasPrefix(".") else { continue }
				
				let itemPath = (rootPath as NSString).appendingPathComponent(itemName)
				var isDirectory: ObjCBool = false
				
				if FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory) {
					if !isDirectory.boolValue && !Comic.isSupportedFile(at: itemPath) {
						continue
					}
					Self.processItem(path: itemPath, isDirectory: isDirectory.boolValue, rootItems: &updatedLibrary, parent: nil)
				}
			}
		}
		
		Self.sort(items: &updatedLibrary)
		
		await MainActor.run {
			library = updatedLibrary
			NotificationCenter.default.post(name: Self.libraryUpdatedNotification, object: nil)
		}
	}

	func clearLibrary() async {
		await MainActor.run {
			library.removeAll()
			NotificationCenter.default.post(name: Self.libraryUpdatedNotification, object: nil)
		}
	}
}
