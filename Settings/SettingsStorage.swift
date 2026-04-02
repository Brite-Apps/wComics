//
//  SettingsStorage.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import Foundation

enum LibraryDirectoryState {
	case notSelected
	case available(URL)
	case unavailable(URL)
}

enum LibraryPresentationMode: Int {
	case grid
	case list
}

@MainActor
class SettingsStorage {
	static let instance = SettingsStorage()
	private static let libraryDirectoryBookmarkKey = "libraryDirectoryBookmark"
	private let settings = UserDefaults.standard

	var libraryDirectoryPath: String? {
		get {
			settings.string(forKey: "libraryDirectoryPath")
		}
		set {
			if let newValue = newValue {
				settings.set(newValue, forKey: "libraryDirectoryPath")
			}
			else {
				settings.removeObject(forKey: "libraryDirectoryPath")
			}
		}
	}
	
	var lastDocument: String? {
		set {
			if let newValue = newValue {
				settings.set(newValue, forKey: "lastDocument")
			}
			else {
				settings.removeObject(forKey: "lastDocument")
			}
		}
		get {
			settings.string(forKey: "lastDocument")
		}
	}

	var libraryPresentationMode: LibraryPresentationMode {
		get {
			LibraryPresentationMode(rawValue: settings.integer(forKey: "libraryPresentationMode")) ?? .grid
		}
		set {
			settings.set(newValue.rawValue, forKey: "libraryPresentationMode")
		}
	}
	
	private init() {
		// singleton stub
	}

	private func storedLibraryDirectoryURL() -> URL? {
#if targetEnvironment(macCatalyst)
		return nil
#else
		guard let libraryDirectoryPath = libraryDirectoryPath else {
			return nil
		}
		return URL(fileURLWithPath: libraryDirectoryPath, isDirectory: true)
#endif
	}

	private func libraryDirectoryBookmarkResolutionOptions() -> URL.BookmarkResolutionOptions {
#if targetEnvironment(macCatalyst)
		return [.withSecurityScope]
#else
		return []
#endif
	}

	private func libraryDirectoryBookmarkCreationOptions() -> URL.BookmarkCreationOptions {
#if targetEnvironment(macCatalyst)
		return [.withSecurityScope, .securityScopeAllowOnlyReadAccess]
#else
		return []
#endif
	}

	func libraryDirectoryURL() -> URL? {
		guard let bookmarkData = settings.data(forKey: Self.libraryDirectoryBookmarkKey) else {
			return storedLibraryDirectoryURL()
		}

		var isStale = false
		do {
			let url = try URL(resolvingBookmarkData: bookmarkData, options: libraryDirectoryBookmarkResolutionOptions(), relativeTo: nil, bookmarkDataIsStale: &isStale)

			if isStale {
				saveLibraryDirectory(url)
			}

			return url
		}
		catch {
			return storedLibraryDirectoryURL()
		}
	}

	func libraryDirectoryState() -> LibraryDirectoryState {
		guard let url = libraryDirectoryURL() else {
			return .notSelected
		}

		let didAccessSecurityScopedResource = url.startAccessingSecurityScopedResource()
		defer {
			if didAccessSecurityScopedResource {
				url.stopAccessingSecurityScopedResource()
			}
		}

		var isDirectory: ObjCBool = false
		let resourceReachable = (try? url.checkResourceIsReachable()) ?? false
		let fileExists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
		let isReachable = resourceReachable && fileExists && isDirectory.boolValue

		if isReachable {
			return .available(url)
		}

		return .unavailable(url)
	}

	func saveLibraryDirectory(_ url: URL) {
#if !targetEnvironment(macCatalyst)
		libraryDirectoryPath = url.path
#endif
		let didAccessSecurityScopedResource = url.startAccessingSecurityScopedResource()
		defer {
			if didAccessSecurityScopedResource {
				url.stopAccessingSecurityScopedResource()
			}
		}
		do {
			let bookmarkData = try url.bookmarkData(options: libraryDirectoryBookmarkCreationOptions(), includingResourceValuesForKeys: nil, relativeTo: nil)
			settings.set(bookmarkData, forKey: Self.libraryDirectoryBookmarkKey)
		}
		catch {
			settings.removeObject(forKey: Self.libraryDirectoryBookmarkKey)
#if targetEnvironment(macCatalyst)
			libraryDirectoryPath = nil
#endif
		}
	}
	
	func currentPage(for file: String) -> Int? {
		return settings.dictionary(forKey: "states")?[file] as? Int
	}
	
	func saveCurrentPage(_ page: Int, for file: String) {
		var states = settings.dictionary(forKey: "states") ?? [:]
		states[file] = page
		settings.set(states, forKey: "states")
	}
	
	func removeSettings(for file: String) {
		var states = settings.dictionary(forKey: "states") ?? [:]
		states.removeValue(forKey: file)
		settings.set(states, forKey: "states")
	}
}
