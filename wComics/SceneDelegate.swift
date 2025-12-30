//
//  SceneDelegate.swift
//  wComics
//
//  Created by Nikita Denin on 30.12.25.
//  Copyright © 2025 Nikita Denin. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?
	private let viewController = ViewerViewController()
	private var updateTask: Task<Void, Never>?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else {
			return
		}

		let window = UIWindow(windowScene: windowScene)
		window.rootViewController = viewController
		window.makeKeyAndVisible()
		self.window = window

		updateLibrary()

		if let url = connectionOptions.urlContexts.first?.url {
			openComic(at: url)
		}
	}

	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		guard let url = URLContexts.first?.url else {
			return
		}

		openComic(at: url)
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		SettingsStorage.instance.lastDocument = viewController.comic?.file
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		updateLibrary()
	}

	private func openComic(at url: URL) {
		if let comic = Comic(file: url.path) {
			viewController.comic = comic
		}
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

	private func updateLibrary() {
		updateTask?.cancel()

		updateTask = Task {
			let coverDir = (DOCPATH as NSString).appendingPathComponent("covers")

			try? FileManager.default.createDirectory(atPath: coverDir, withIntermediateDirectories: true)

			await LibraryDataSource.instance.updateLibrary()

			await MainActor.run {
				checkOpen()
			}
		}
	}
}
