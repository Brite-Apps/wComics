//
//  ComicItem.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nik S Dyonin. All rights reserved.
//

class ComicItem: Comparable, Equatable {
	static func == (lhs: ComicItem, rhs: ComicItem) -> Bool {
		return (lhs.path as NSString).lastPathComponent.lowercased() < (rhs.path as NSString).lastPathComponent.lowercased()
	}
	
	static func < (lhs: ComicItem, rhs: ComicItem) -> Bool {
		return (lhs.path as NSString).lastPathComponent.lowercased() < (rhs.path as NSString).lastPathComponent.lowercased()
	}
	
	let path: String
	let isDir: Bool
	var children = [ComicItem]()
	
	init(path: String, isDir: Bool) {
		self.path = path
		self.isDir = isDir
	}
}
