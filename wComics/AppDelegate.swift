//
//  AppDelegate.swift
//  wComics
//
//  Created by Nikita Denin on 27.09.24.
//  Copyright © 2024 Nik S Dyonin. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	private var justStarted = false
	internal var window: UIWindow?
	private let viewController = ViewerViewController()
	private var updateTask: Task<Void, Never>?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		window = UIWindow(frame: UIScreen.main.bounds)
		window?.rootViewController = viewController
		window?.makeKeyAndVisible()
		
		justStarted = true
		
		updateLibrary()
		
		return true
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		if let comic = Comic(file: url.path) {
			viewController.comic = comic
			return true
		}
		
		return false
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		SettingsStorage.instance.lastDocument = viewController.comic?.file
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		updateLibrary()
	}
	
	@MainActor
	private func checkOpen() {
		if let lastDocument = SettingsStorage.instance.lastDocument {
			if let comic = Comic(file: lastDocument) {
				viewController.comic = comic
			}
			else {
				viewController.comic = nil
			}
		}
		else {
			viewController.comic = nil
		}
	}
	
	func updateLibrary() {
		updateTask?.cancel()
		
		updateTask = Task {
			let coverDir = (DOCPATH as NSString).appendingPathComponent("covers")
			
			try? FileManager.default.createDirectory(atPath: coverDir, withIntermediateDirectories: true)
			
			await LibraryDataSource.instance.updateLibrary()
			
			justStarted = false
			
			await MainActor.run {
				checkOpen()
			}
		}
	}
}
