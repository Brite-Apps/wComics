//
//  ViewerViewController.swift
//  wComics
//
//  Created by Nikita Denin on 27.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import UIKit

class ViewerViewController: UIViewController  {
	@MainActor
	var comic: Comic? {
		willSet {
			if let currentComic = comic {
				SettingsStorage.instance.saveCurrentPage(currentPage, for: currentComic.file)
			}
		}
		didSet {
			if let newValue = comic {
				if oldValue != comic {
					guard FileManager.default.fileExists(atPath: newValue.file, isDirectory: nil) else {
						showErrorAlert()
						return
					}
					
					if let currentComic = comic {
						SettingsStorage.instance.saveCurrentPage(currentPage, for: currentComic.file)
					}
					
					currentPage = SettingsStorage.instance.currentPage(for: newValue.file) ?? 0
					totalPages = newValue.numberOfPages
					
					bottomToolbar.pageNumber = currentPage + 1
					bottomToolbar.totalPages = totalPages
					
					SettingsStorage.instance.lastDocument = newValue.file
					
					topLabel.text = newValue.title
					
					currentPageView.viewForZoom?.removeFromSuperview()
					currentPageView.viewForZoom = nil
					
					displayPage(currentPage, animationDirection: 0)
				}
			}
			else {
				SettingsStorage.instance.lastDocument = nil
				bottomToolbar.pageNumber = -1
				topLabel.text = "wComics"
				
				if toolbarHidden {
					toggleToolbars()
				}
				
				currentPageView.viewForZoom?.removeFromSuperview()
				currentPageView.viewForZoom = nil
			}
		}
	}
	
	private static let toolbarHeight: CGFloat = 72
	private static let topLabelHeight: CGFloat = 48
	private let pagesView = UIView()
	private var currentPageView = ScrollView()
	private var currentPage = 0
	private var totalPages = 0
	private var animating = false
	private let topLabel = UILabel()
	private let bottomToolbar = SliderToolbar()
	private let libraryButton = UIButton(type: .custom)
	private let wifiButton = UIButton(type: .custom)
	private let infoButton = UIButton(type: .custom)
	private var toolbarHidden = true
	private var libraryNavigationController: UINavigationController?
	override var prefersStatusBarHidden: Bool { true }
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = .black
		
		bottomToolbar.backgroundColor = .black.withAlphaComponent(0.8)
		bottomToolbar.delegate = self
		bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
		
		view.addSubview(bottomToolbar)

		topLabel.backgroundColor = bottomToolbar.backgroundColor
		topLabel.numberOfLines = 1
		topLabel.font = UIFont.preferredFont(forTextStyle: .headline)
		topLabel.textColor = .white
		topLabel.textAlignment = .center
		topLabel.text = "wComics"
		topLabel.lineBreakMode = .byTruncatingTail
		topLabel.translatesAutoresizingMaskIntoConstraints = false
		
		view.addSubview(topLabel)
		
		libraryButton.setImage(UIImage(named: "folder")?.withRenderingMode(.alwaysTemplate), for: .normal)
		libraryButton.tintColor = .white
		libraryButton.imageView?.tintColor = .white
		libraryButton.imageView?.contentMode = .scaleAspectFit
		libraryButton.addTarget(self, action: #selector(showLibrary), for: .touchUpInside)
		libraryButton.translatesAutoresizingMaskIntoConstraints = false
		
		bottomToolbar.addSubview(libraryButton)
		
		wifiButton.setImage(UIImage(named: "wifi")?.withRenderingMode(.alwaysTemplate), for: .normal)
		wifiButton.tintColor = .white
		wifiButton.imageView?.tintColor = .white
		wifiButton.imageView?.contentMode = .scaleAspectFit
		wifiButton.addTarget(self, action: #selector(startServer), for: .touchUpInside)
		wifiButton.translatesAutoresizingMaskIntoConstraints = false
		
		bottomToolbar.addSubview(wifiButton)
		
		infoButton.setImage(UIImage(named: "info")?.withRenderingMode(.alwaysTemplate), for: .normal)
		infoButton.tintColor = .white
		infoButton.imageView?.tintColor = .white
		infoButton.imageView?.contentMode = .scaleAspectFit
		infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
		infoButton.translatesAutoresizingMaskIntoConstraints = false
		
		bottomToolbar.addSubview(infoButton)
		
		bottomToolbar.pageNumber = -1
		
		pagesView.translatesAutoresizingMaskIntoConstraints = false
		
		view.insertSubview(pagesView, belowSubview: bottomToolbar)
		
		currentPageView.translatesAutoresizingMaskIntoConstraints = false
		
		pagesView.addSubview(currentPageView)
		
		let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
		doubleTapRecognizer.numberOfTapsRequired = 2
		
		pagesView.addGestureRecognizer(doubleTapRecognizer)
		
		let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
		singleTapRecognizer.numberOfTapsRequired = 1
		singleTapRecognizer.require(toFail: doubleTapRecognizer)
		
		pagesView.addGestureRecognizer(singleTapRecognizer)
		
		let swipeLeftRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
		swipeLeftRecognizer.numberOfTouchesRequired = 1
		swipeLeftRecognizer.direction = .left
		
		pagesView.addGestureRecognizer(swipeLeftRecognizer)
		
		let swipeRightRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
		swipeRightRecognizer.numberOfTouchesRequired = 1
		swipeRightRecognizer.direction = .right
		
		pagesView.addGestureRecognizer(swipeRightRecognizer)
		
		NSLayoutConstraint.activate([
			bottomToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			bottomToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			bottomToolbar.heightAnchor.constraint(equalToConstant: Self.toolbarHeight),
			bottomToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			
			topLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			topLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			topLabel.heightAnchor.constraint(equalToConstant: Self.topLabelHeight),
			topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			
			pagesView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
			pagesView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
			pagesView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			pagesView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			
			currentPageView.leadingAnchor.constraint(equalTo: pagesView.leadingAnchor),
			currentPageView.trailingAnchor.constraint(equalTo: pagesView.trailingAnchor),
			currentPageView.topAnchor.constraint(equalTo: pagesView.topAnchor),
			currentPageView.bottomAnchor.constraint(equalTo: pagesView.bottomAnchor),
			
			libraryButton.bottomAnchor.constraint(equalTo: bottomToolbar.bottomAnchor, constant: -6),
			libraryButton.leadingAnchor.constraint(equalTo: bottomToolbar.leadingAnchor, constant: 20),
			libraryButton.widthAnchor.constraint(equalToConstant: 32),
			libraryButton.heightAnchor.constraint(equalToConstant: 32),
			
			wifiButton.bottomAnchor.constraint(equalTo: bottomToolbar.bottomAnchor, constant: -6),
			wifiButton.leadingAnchor.constraint(equalTo: libraryButton.trailingAnchor, constant: 15),
			wifiButton.widthAnchor.constraint(equalToConstant: 32),
			wifiButton.heightAnchor.constraint(equalToConstant: 32),
			
			infoButton.bottomAnchor.constraint(equalTo: bottomToolbar.bottomAnchor, constant: -6),
			infoButton.trailingAnchor.constraint(equalTo: bottomToolbar.trailingAnchor, constant: -20),
			infoButton.widthAnchor.constraint(equalToConstant: 32),
			infoButton.heightAnchor.constraint(equalToConstant: 32),
		])
		
		if comic == nil {
			toggleToolbars()
		}
	}
	
	private func showErrorAlert() {
		let alert = UIAlertController(title: "WARNING".localized(), message: "CANNOT_OPEN_FILE".localized(), preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK".localized(), style: .default))
		
		present(alert, animated: true)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		updateZoomParamsScaling(scaleWidth: UIDevice.current.userInterfaceIdiom != .pad && size.width > size.height)
	}
	
	@objc private func showLibrary() {
		if libraryNavigationController == nil {
			let libraryViewController = LibraryViewController(dataSource: LibraryDataSource.instance.library)
			libraryViewController.title = "LIBRARY".localized()
			libraryViewController.delegate = self
			
			libraryNavigationController = UINavigationController(rootViewController: libraryViewController)
			libraryNavigationController?.modalPresentationStyle = .formSheet
		}
		
		present(libraryNavigationController!, animated: true)
	}
	
	@objc private func startServer() {
		let v = ServerViewController()
		
		let nav = UINavigationController(rootViewController: v)
		nav.modalPresentationStyle = .formSheet
		nav.modalTransitionStyle = .coverVertical
		
		let closeItem = UIBarButtonItem(title: "STOP_SERVER".localized(), style: .done, target: self, action: #selector(stopServer))
		
		v.navigationItem.rightBarButtonItem = closeItem
		
		present(nav, animated: true)
	}
	
	@objc private func stopServer() {
		dismiss(animated: true)

		Task {
			await LibraryDataSource.instance.updateLibrary()
		}
	}
	
	@objc private func showInfo() {
		let v = InfoViewController()

		let nav = UINavigationController(rootViewController: v)
		nav.modalPresentationStyle = .formSheet
		nav.modalTransitionStyle = .coverVertical
		
		let closeItem = UIBarButtonItem(title: "CLOSE".localized(), style: .done, target: self, action: #selector(closeInfoViewController))
		
		v.navigationItem.rightBarButtonItem = closeItem
		
		present(nav, animated: true)
	}
	
	@objc private func closeInfoViewController() {
		dismiss(animated: true)
	}
	
	@objc private func handleDoubleTap() {
		updateZoomParamsScaling(scaleWidth: true)
	}
	
	private func updateZoomParamsScaling(scaleWidth: Bool) {
		let imageSize = currentPageView.pageRect.size
		let nScaleWidth = currentPageView.frame.size.width / imageSize.width
		let nScaleHeight = currentPageView.frame.size.height / imageSize.height
		let minimumZoom = min(nScaleWidth, nScaleHeight)
		
		currentPageView.minimumZoomScale = minimumZoom
		
		if scaleWidth {
			currentPageView.setZoomScale(nScaleWidth, animated: false)
		}
		else {
			currentPageView.setZoomScale(minimumZoom, animated: false)
		}
		
		currentPageView.scrollViewDidZoom(currentPageView)
		currentPageView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
	}
	
	@objc private func handleSingleTap(_ sender: UITapGestureRecognizer) {
		guard comic != nil else { return }
		
		let location = sender.location(in: view)
		let quarterWidth = view.bounds.width * 0.25
		
		if location.x <= quarterWidth {
			displayPage(currentPage - 1, animationDirection: 1)
		}
		else if location.x >= view.bounds.width - quarterWidth {
			displayPage(currentPage + 1, animationDirection: -1)
		}
		else {
			toggleToolbars()
		}
	}
	
	private func toggleToolbars() {
		toolbarHidden = !toolbarHidden
		
		if toolbarHidden {
			UIView.animate(withDuration: 0.3) { [weak self] in
				self?.bottomToolbar.alpha = 0
				self?.topLabel.alpha = 0
			}
		}
		else {
			UIView.animate(withDuration: 0.3) { [weak self] in
				self?.bottomToolbar.alpha = 1
				self?.topLabel.alpha = 1
			}
		}
	}
	
	private func displayPage(_ page: Int, animationDirection: Int) {
		guard let comic = comic else { return }
		guard 0..<totalPages ~= page else { return }
		
		var oldPageView: ScrollView? = nil
		
		if animationDirection != 0 {
			oldPageView = currentPageView
			
			currentPageView = ScrollView()
			currentPageView.alpha = 0
			currentPageView.translatesAutoresizingMaskIntoConstraints = false
			
			if animationDirection == 1 {
				if let oldPageView = oldPageView {
					pagesView.insertSubview(currentPageView, aboveSubview: oldPageView)
				}
				else {
					pagesView.insertSubview(currentPageView, at: 0)
				}
			}
			else {
				if let oldPageView = oldPageView {
					pagesView.insertSubview(currentPageView, belowSubview: oldPageView)
				}
				else {
					pagesView.insertSubview(currentPageView, at: 0)
				}
			}
		}
		
		NSLayoutConstraint.activate([
			currentPageView.leadingAnchor.constraint(equalTo: pagesView.leadingAnchor),
			currentPageView.trailingAnchor.constraint(equalTo: pagesView.trailingAnchor),
			currentPageView.topAnchor.constraint(equalTo: pagesView.topAnchor),
			currentPageView.bottomAnchor.constraint(equalTo: pagesView.bottomAnchor),
		])
		
		view.layoutIfNeeded()
		
		if animationDirection == 1 {
			currentPageView.transform = currentPageView.transform.translatedBy(x: -pagesView.bounds.width, y: 0)
		}
		
		pagesView.isUserInteractionEnabled = false
		
		if let img = comic.imageAtIndex(page, screenSize: pagesView.bounds.size) {
			var pageRect = CGRect(origin: .zero, size: img.size)
			let c = pagesView.bounds.height / pageRect.height
			pageRect.size.width = floor(c * pageRect.width * 0.5)
			pageRect.size.height = floor(c * pageRect.height * 0.5)
			
			currentPageView.pageRect = pageRect
			
			let pageContentView = UIView(frame: pageRect)
			pageContentView.backgroundColor = .white
			
			let tiledLayer = CATiledLayer()
			tiledLayer.bounds = pageRect
			tiledLayer.delegate = nil
			tiledLayer.tileSize = CGSize(width: 256, height: 256)
			tiledLayer.levelsOfDetail = 5
			tiledLayer.levelsOfDetailBias = 5
			tiledLayer.backgroundColor = UIColor.white.cgColor
			tiledLayer.frame = pageRect
			
			pageContentView.layer.addSublayer(tiledLayer)
			
			tiledLayer.contents = img.cgImage
			
			currentPageView.addSubview(pageContentView)
			
			currentPageView.viewForZoom = pageContentView
		}
		
		currentPage = page
		
		bottomToolbar.pageNumber = currentPage + 1
		
		pageChanged()
		
		let isLandscape = view.window?.windowScene?.interfaceOrientation.isLandscape ?? false
		updateZoomParamsScaling(scaleWidth: UIDevice.current.userInterfaceIdiom != .pad && isLandscape)
		
		pagesView.isUserInteractionEnabled = true
		
		if let oldPageView = oldPageView {
			UIView.animate(withDuration: 0.3) { [weak self] in
				self?.currentPageView.transform = .identity
				self?.currentPageView.alpha = 1
				
				if animationDirection != 1 {
					if animationDirection == -1 {
						oldPageView.transform = oldPageView.transform.translatedBy(x: -oldPageView.bounds.width, y: 0)
					}
					else {
						oldPageView.transform = oldPageView.transform.translatedBy(x: oldPageView.bounds.width, y: 0)
					}
					
					oldPageView.alpha = 0
				}
			} completion: { finished in
				oldPageView.removeFromSuperview()
			}
		}
		else {
			currentPageView.transform = .identity
			currentPageView.alpha = 1
		}
	}
	
	private func pageChanged() {
		guard let comic = comic else { return }
		SettingsStorage.instance.saveCurrentPage(currentPage, for: comic.file)
	}
	
	@objc private func handleSwipe(_ sender: UISwipeGestureRecognizer) {
		guard comic != nil else { return }
		guard sender.state == .recognized else { return }
		
		if sender.direction == .left {
			displayPage(currentPage + 1, animationDirection: -1)
		}
		else if sender.direction == .right {
			displayPage(currentPage - 1, animationDirection: 1)
		}
	}
}

extension ViewerViewController: SliderToolbarDelegate {
	@MainActor
	func sliderValueChanged(value: Float) {
		currentPage = Int(Float(totalPages) * value)
		
		currentPageView.viewForZoom?.removeFromSuperview()
		currentPageView.viewForZoom = nil

		displayPage(currentPage, animationDirection: 0)
	}
}

extension ViewerViewController: LibraryViewControllerDelegate {
	func comicItemSelected(_ item: ComicItem) {
		dismiss(animated: true) { [weak self] in
			if (item.path as NSString).resolvingSymlinksInPath != (self?.comic?.file as? NSString)?.resolvingSymlinksInPath {
				if let newComic = Comic(file: item.path) {
					self?.comic = newComic
				}
			}
		}
	}
	
	func currentComic() -> Comic? {
		return comic
	}
	
	func comicRemoved(_ item: ComicItem) {
		if (comic?.file as? NSString)?.resolvingSymlinksInPath == (item.path as NSString).resolvingSymlinksInPath || comic?.somewhereInSubdir(of: item.path) == true {
			comic = nil
		}
	}
	
	func forceUpdateLibrary() {
		libraryNavigationController = nil
		
		Task {
			await LibraryDataSource.instance.updateLibrary()
		}
	}
}
