//
//  AppDelegate.swift
//  wComics
//
//  Created by Nikita Denin on 27.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		return true
	}

	#if targetEnvironment(macCatalyst)
	override func buildMenu(with builder: UIMenuBuilder) {
		super.buildMenu(with: builder)
		guard builder.system == UIMenuSystem.main else { return }
		
		builder.remove(menu: .standardEdit)
		builder.remove(menu: .format)
		builder.remove(menu: .edit)
		
		builder.replaceChildren(ofMenu: .about) { element in
			let aboutCommand = UICommand(title: "About wComics", image: UIImage(systemName: "info.circle"), action: #selector(ViewerViewController.showInfo))
			return [aboutCommand]
		}
		
		builder.replaceChildren(ofMenu: .file) { element in
			let libraryCommand = UIKeyCommand(title: "Library", image: UIImage(systemName: "building.columns.circle"), action: #selector(ViewerViewController.showLibrary), input: "l", modifierFlags: [.command])
			return [libraryCommand]
		}
	}
	#endif

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		let configuration = UISceneConfiguration(name: "default", sessionRole: connectingSceneSession.role)
		configuration.delegateClass = SceneDelegate.self
		return configuration
	}
}
