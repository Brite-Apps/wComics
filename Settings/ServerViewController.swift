//
//  ServerViewController.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nik S Dyonin. All rights reserved.
//

import UIKit

class ServerViewController: UIViewController {
	nonisolated(unsafe) private let webUploader = GCDWebUploader(uploadDirectory: DOCPATH)
	private let urlLabel = UILabel()
	private let wifiImageView = UIImageView(image: UIImage(named: "wifi-big-image"))
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		webUploader.start()
		
		view.backgroundColor = .white
		
		wifiImageView.contentMode = .scaleAspectFit
		wifiImageView.translatesAutoresizingMaskIntoConstraints = false
		
		view.addSubview(wifiImageView)
		
		urlLabel.backgroundColor = .clear
		urlLabel.numberOfLines = 0
		urlLabel.lineBreakMode = .byWordWrapping
		urlLabel.textColor = .black
		urlLabel.font = UIFont.preferredFont(forTextStyle: .title2)
		urlLabel.textAlignment = .center
		urlLabel.translatesAutoresizingMaskIntoConstraints = false
		
		if let serverUrl = webUploader.serverURL?.absoluteString {
			urlLabel.text = String(format: "UPLOAD_STRING".localized(), serverUrl)
		}
		else {
			urlLabel.text = "SERVER_NOT_RUNNING".localized()
		}
		
		view.addSubview(urlLabel)
		
		NSLayoutConstraint.activate([
			wifiImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
			wifiImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
			wifiImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
			wifiImageView.heightAnchor.constraint(equalTo: wifiImageView.widthAnchor, multiplier: 1),
			
			urlLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
			urlLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
			urlLabel.topAnchor.constraint(equalTo: wifiImageView.bottomAnchor, constant: 50),
		])

		UIApplication.shared.isIdleTimerDisabled = true
	}

	deinit {
		webUploader.stop()
		
		Task {
			await MainActor.run {
				UIApplication.shared.isIdleTimerDisabled = false
			}
		}
	}
}
