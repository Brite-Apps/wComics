//
//  LibraryDataSource.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nik S Dyonin. All rights reserved.
//

@MainActor
class LibraryDataSource {
	static let instance = LibraryDataSource()
	static let libraryUpdatedNotification = Notification.Name("LibraryUpdated")
	var library = [ComicItem]()

	private init() {
		// singleton stub
	}

	private func processItem(path: String, isDirectory: Bool, parent: ComicItem?) {
		let item = ComicItem(path: path, isDir: isDirectory)
		
		if let parent = parent {
			var children = parent.children
			children.append(item)
		}
		else {
			library.append(item)
		}
		
		if isDirectory {
			if let itemsList = try? FileManager.default.contentsOfDirectory(atPath: path), !itemsList.isEmpty {
				for itemName in itemsList {
					let p = (path as NSString).appendingPathComponent(itemName)
					var isDir: ObjCBool = false
					
					if FileManager.default.fileExists(atPath: p, isDirectory: &isDir) {
						processItem(path: p, isDirectory: isDir.boolValue, parent: item)
					}
				}
			}
		}
	}
	
	private func sort(items: inout [ComicItem]) {
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
	
	func updateLibrary() async {
		library.removeAll()
		
		if let itemsList = try? FileManager.default.contentsOfDirectory(atPath: DOCPATH), !itemsList.isEmpty {
			for itemName in itemsList {
				guard itemName != "covers" else { continue }
				guard !itemName.hasPrefix(".") else { continue }
				
				let itemPath = (DOCPATH as NSString).appendingPathComponent(itemName)
				var isDirectory: ObjCBool = false
				
				if FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory) {
					processItem(path: itemPath, isDirectory: isDirectory.boolValue, parent: nil)
				}
			}
		}
		
		sort(items: &library)
		
		await MainActor.run {
			NotificationCenter.default.post(name: Self.libraryUpdatedNotification, object: nil)
		}
	}
}
