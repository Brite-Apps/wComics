//
//  InfoViewController.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nik S Dyonin. All rights reserved.
//

import UIKit
import WebKit

class InfoViewController: UIViewController, WKNavigationDelegate {
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let configuration = WKWebViewConfiguration()
		configuration.dataDetectorTypes = []
		
		let webView = WKWebView(frame: .zero, configuration: configuration)
		webView.backgroundColor = .white
		webView.navigationDelegate = self
		webView.translatesAutoresizingMaskIntoConstraints = false
		
		view.addSubview(webView)
		
		NSLayoutConstraint.activate([
			webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			webView.topAnchor.constraint(equalTo: view.topAnchor),
			webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
		])
		
		if let htmlString = try? String(contentsOfFile: Bundle.main.path(forResource: "info", ofType: "html")!, encoding: .utf8) {
			webView.loadHTMLString(htmlString, baseURL: nil)
		}
	}
	
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
		guard let url = navigationAction.request.url else {
			return .cancel
		}
		
		let scheme = url.scheme
		
		if scheme == "http" || scheme == "https" || scheme == "mailto" {
			await UIApplication.shared.open(url)
			return .cancel
		}
		
		return .allow
	}
}
