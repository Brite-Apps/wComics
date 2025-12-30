//
//  SettingsStorage.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import Foundation

@MainActor
class SettingsStorage {
	static let instance = SettingsStorage()
	private let settings = UserDefaults.standard
	
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
	
	private init() {
		// singleton stub
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
