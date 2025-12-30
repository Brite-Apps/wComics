//
//  InfoViewController.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .white

		let scrollView = UIScrollView()
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(scrollView)

		let contentView = UIView()
		contentView.translatesAutoresizingMaskIntoConstraints = false
		scrollView.addSubview(contentView)

		let iconView = UIImageView(image: UIImage(named: "info")?.withRenderingMode(.alwaysTemplate))
		iconView.tintColor = .black
		iconView.contentMode = .scaleAspectFit
		iconView.translatesAutoresizingMaskIntoConstraints = false

		let titleLabel = UILabel()
		titleLabel.text = "wComics"
		titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
		titleLabel.textColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
		titleLabel.textAlignment = .center

		let descriptionLabel = UILabel()
		descriptionLabel.text = "CBZ / CBR / PDF comic files viewer.\n© 2011-2026 Brite Apps"
		descriptionLabel.font = UIFont.systemFont(ofSize: 16.5)
		descriptionLabel.textColor = UIColor(red: 0.44, green: 0.44, blue: 0.44, alpha: 1.0)
		descriptionLabel.numberOfLines = 0
		descriptionLabel.textAlignment = .center

		let linkButton = UIButton(type: .system)
		linkButton.setTitle("https://github.com/Brite-Apps/wComics", for: .normal)
		linkButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.5)
		linkButton.titleLabel?.numberOfLines = 0
		linkButton.titleLabel?.textAlignment = .center
		linkButton.addTarget(self, action: #selector(openRepositoryLink), for: .touchUpInside)

		let gcdWebServerLabel = UILabel()
		gcdWebServerLabel.text = "Uses GCDWebServer © 2012-2014 Pierre-Olivier Latour"
		gcdWebServerLabel.font = UIFont.systemFont(ofSize: 16.5)
		gcdWebServerLabel.textColor = UIColor(red: 0.44, green: 0.44, blue: 0.44, alpha: 1.0)
		gcdWebServerLabel.numberOfLines = 0
		gcdWebServerLabel.textAlignment = .center

		let gcdWebServerButton = UIButton(type: .system)
		gcdWebServerButton.setTitle("https://github.com/swisspol/GCDWebServer", for: .normal)
		gcdWebServerButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.5)
		gcdWebServerButton.titleLabel?.numberOfLines = 0
		gcdWebServerButton.titleLabel?.textAlignment = .center
		gcdWebServerButton.addTarget(self, action: #selector(openGCDWebServerLink), for: .touchUpInside)

		let stackView = UIStackView(arrangedSubviews: [
			iconView,
			titleLabel,
			descriptionLabel,
			linkButton,
			gcdWebServerLabel,
			gcdWebServerButton,
		])
		
		stackView.axis = .vertical
		stackView.alignment = .center
		stackView.spacing = 12
		stackView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(stackView)

		let safeArea = view.safeAreaLayoutGuide

		NSLayoutConstraint.activate([
			scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
			scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
			scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
			scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),

			contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
			contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
			contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
			contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
			contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

			stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
			stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
			stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
			stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),

			iconView.heightAnchor.constraint(lessThanOrEqualToConstant: 400),
			iconView.widthAnchor.constraint(lessThanOrEqualTo: stackView.widthAnchor),

			titleLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
			descriptionLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
			linkButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
			gcdWebServerLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
			gcdWebServerButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
		])
	}

	@objc private func openRepositoryLink() {
		guard let url = URL(string: "https://github.com/Brite-Apps/wComics") else {
			return
		}
		
		UIApplication.shared.open(url)
	}

	@objc private func openGCDWebServerLink() {
		guard let url = URL(string: "https://github.com/swisspol/GCDWebServer") else {
			return
		}

		UIApplication.shared.open(url)
	}
}
