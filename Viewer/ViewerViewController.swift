//
//  ViewerViewController.swift
//  wComics
//
//  Created by Nikita Denin on 27.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

class ViewerViewController: UIViewController, UIDocumentPickerDelegate, UIGestureRecognizerDelegate  {
	private var libraryDirectoryPickerController: UIDocumentPickerViewController?

	private func updateWindowHeader() {
		guard IS_MAC_CATALYST, let windowScene = view.window?.windowScene else {
			return
		}

		windowScene.title = comic?.title ?? "wComics"
		windowScene.subtitle = (SettingsStorage.instance.libraryDirectoryURL()?.path as NSString?)?.abbreviatingWithTildeInPath ?? ""
	}

	override var canBecomeFirstResponder: Bool { true }

	override var keyCommands: [UIKeyCommand]? {
		let previousPageCommand = UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(handlePreviousPageKeyCommand))
		let nextPageCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(handleNextPageKeyCommand))
		let togglePanelsCommand = UIKeyCommand(input: " ", modifierFlags: [], action: #selector(handleTogglePanelsKeyCommand))
		previousPageCommand.wantsPriorityOverSystemBehavior = true
		nextPageCommand.wantsPriorityOverSystemBehavior = true
		togglePanelsCommand.wantsPriorityOverSystemBehavior = true
		return [previousPageCommand, nextPageCommand, togglePanelsCommand]
	}

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

					currentPage = SettingsStorage.instance.currentPage(for: newValue.file) ?? 0
					totalPages = newValue.numberOfPages
					
					bottomToolbar.pageNumber = currentPage + 1
					bottomToolbar.totalPages = totalPages
					
					SettingsStorage.instance.lastDocument = newValue.file
					
					topLabel.text = newValue.title
					updateWindowHeader()
					
					currentPageView.viewForZoom?.removeFromSuperview()
					currentPageView.viewForZoom = nil
					
					displayPage(currentPage, animationDirection: 0)
				}
			}
			else {
				SettingsStorage.instance.lastDocument = nil
				bottomToolbar.pageNumber = -1
				topLabel.text = "wComics"
				updateWindowHeader()
				
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
	private let swipeLeftRecognizer = UISwipeGestureRecognizer()
	private let swipeRightRecognizer = UISwipeGestureRecognizer()
	private var toolbarHidden = true
	private var libraryNavigationController: UINavigationController?
	private var hasPresentedLibraryDirectoryPrompt = false
	private var hasPresentedLibraryDirectoryUnavailableAlert = false
	private var lastPagesViewSize = CGSize.zero
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
		
		if !IS_MAC_CATALYST {
			libraryButton.setImage(UIImage(named: "folder")?.withRenderingMode(.alwaysTemplate), for: .normal)
			libraryButton.tintColor = .white
			libraryButton.imageView?.tintColor = .white
			libraryButton.imageView?.contentMode = .scaleAspectFit
			libraryButton.addTarget(self, action: #selector(showLibrary), for: .touchUpInside)
			libraryButton.translatesAutoresizingMaskIntoConstraints = false
			
			bottomToolbar.addSubview(libraryButton)
		}
		
		if !IS_MAC_CATALYST {
			wifiButton.setImage(UIImage(named: "wifi")?.withRenderingMode(.alwaysTemplate), for: .normal)
			wifiButton.tintColor = .white
			wifiButton.imageView?.tintColor = .white
			wifiButton.imageView?.contentMode = .scaleAspectFit
			wifiButton.addTarget(self, action: #selector(startServer), for: .touchUpInside)
			wifiButton.translatesAutoresizingMaskIntoConstraints = false
			
			bottomToolbar.addSubview(wifiButton)
		}
		
		if !IS_MAC_CATALYST {
			infoButton.setImage(UIImage(named: "info")?.withRenderingMode(.alwaysTemplate), for: .normal)
			infoButton.tintColor = .white
			infoButton.imageView?.tintColor = .white
			infoButton.imageView?.contentMode = .scaleAspectFit
			infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
			infoButton.translatesAutoresizingMaskIntoConstraints = false
			
			bottomToolbar.addSubview(infoButton)
		}
		
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
		
		swipeLeftRecognizer.addTarget(self, action: #selector(handleSwipe(_:)))
		swipeLeftRecognizer.numberOfTouchesRequired = 1
		swipeLeftRecognizer.direction = .left
		swipeLeftRecognizer.delegate = self
		
		pagesView.addGestureRecognizer(swipeLeftRecognizer)
		
		swipeRightRecognizer.addTarget(self, action: #selector(handleSwipe(_:)))
		swipeRightRecognizer.numberOfTouchesRequired = 1
		swipeRightRecognizer.direction = .right
		swipeRightRecognizer.delegate = self
		
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
		])
		
		if !IS_MAC_CATALYST {
			NSLayoutConstraint.activate([
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
		}
		
		if comic == nil {
			toggleToolbars()
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		becomeFirstResponder()
		updateWindowHeader()
		presentLibraryDirectorySetupIfNeeded()
	}

	override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		for press in presses {
			guard let key = press.key else { continue }

			switch key.keyCode {
				case .keyboardLeftArrow:
					showPreviousPage()
					return
				case .keyboardRightArrow:
					showNextPage()
					return
				case .keyboardSpacebar:
					togglePanelsIfNeeded()
					return
				default:
					break
			}
		}

		super.pressesBegan(presses, with: event)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		refreshCurrentPageLayoutIfNeeded(for: pagesView.bounds.size)
	}

	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		if action == #selector(showLibrary) || action == #selector(showInfo) {
			return true
		}

		return super.canPerformAction(action, withSender: sender)
	}

	private func libraryDirectoryAlertPresenter() -> UIViewController? {
		if let presentedViewController {
			if presentedViewController is UIAlertController || presentedViewController is UIDocumentPickerViewController {
				return nil
			}
			return presentedViewController
		}

		return self
	}

	private func libraryDirectoryPickerPresenter() -> UIViewController {
		var presenter: UIViewController = self
		while let presented = presenter.presentedViewController,
			  !(presented is UIAlertController),
			  !(presented is UIDocumentPickerViewController) {
			presenter = presented
		}
		return presenter
	}

	@MainActor
	func presentLibraryDirectorySetupIfNeeded() {
		guard IS_MAC_CATALYST else {
			return
		}

		guard SettingsStorage.instance.libraryDirectoryURL() == nil else {
			return
		}

		guard !hasPresentedLibraryDirectoryPrompt else {
			return
		}

		guard let presenter = libraryDirectoryAlertPresenter() else { return }

		hasPresentedLibraryDirectoryPrompt = true

		let alert = UIAlertController(title: "Select Library Folder", message: "Choose the folder that contains your comics to build the library.", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Select Folder", style: .default) { [weak self] _ in
			self?.hasPresentedLibraryDirectoryPrompt = false
			DispatchQueue.main.async {
				self?.presentLibraryDirectoryPicker()
			}
		})
		alert.addAction(UIAlertAction(title: "Later", style: .cancel) { [weak self] _ in
			self?.hasPresentedLibraryDirectoryPrompt = false
		})
		presenter.present(alert, animated: true)
	}

	@MainActor
	func presentLibraryDirectoryUnavailableAlert(for url: URL) {
		guard IS_MAC_CATALYST else {
			return
		}

		guard !hasPresentedLibraryDirectoryUnavailableAlert else {
			return
		}

		guard let presenter = libraryDirectoryAlertPresenter() else { return }

		hasPresentedLibraryDirectoryUnavailableAlert = true

		let alert = UIAlertController(title: "Library Folder Unavailable", message: "The selected library folder is currently unavailable.\n\n\(url.path)", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Keep Current", style: .cancel) { [weak self] _ in
			self?.hasPresentedLibraryDirectoryUnavailableAlert = false
		})
		alert.addAction(UIAlertAction(title: "Select New Folder", style: .default) { [weak self] _ in
			self?.hasPresentedLibraryDirectoryUnavailableAlert = false
			DispatchQueue.main.async {
				self?.presentLibraryDirectoryPicker()
			}
		})
		presenter.present(alert, animated: true)
	}
	
	private func showErrorAlert() {
		let alert = UIAlertController(title: "WARNING".localized(), message: "CANNOT_OPEN_FILE".localized(), preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK".localized(), style: .default))
		
		present(alert, animated: true)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)

		lastPagesViewSize = .zero
	}

	func handleSceneGeometryChange(to size: CGSize) {
		lastPagesViewSize = .zero
		guard isViewLoaded else { return }
		refreshCurrentPageLayoutIfNeeded(for: size)
	}
	
	@objc func showLibrary() {
		if IS_MAC_CATALYST {
			switch SettingsStorage.instance.libraryDirectoryState() {
			case .notSelected:
				presentLibraryDirectorySetupIfNeeded()
				return
			case .unavailable(let url):
				presentLibraryDirectoryUnavailableAlert(for: url)
				return
			case .available:
				break
			}
		}

		if libraryNavigationController == nil {
			let libraryViewController = LibraryViewController(dataSource: LibraryDataSource.instance.library, showsLibraryRootActions: true)
			libraryViewController.title = "LIBRARY".localized()
			libraryViewController.delegate = self
			
			libraryNavigationController = UINavigationController(rootViewController: libraryViewController)
			libraryNavigationController?.modalPresentationStyle = .formSheet
		}
		
		present(libraryNavigationController!, animated: true)
	}

	private func presentLibraryDirectoryPicker() {
#if targetEnvironment(macCatalyst)
		let picker = UIDocumentPickerViewController(documentTypes: [UTType.folder.identifier], in: .open)
#else
		let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
#endif
		libraryDirectoryPickerController = picker
		picker.allowsMultipleSelection = false
		picker.delegate = self
		picker.presentationController?.delegate = self
		picker.directoryURL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
		let presenter = libraryDirectoryPickerPresenter()
		presenter.present(picker, animated: true)
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

		forceUpdateLibrary()
	}
	
	@objc func showInfo() {
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
			showPreviousPage()
		}
		else if location.x >= view.bounds.width - quarterWidth {
			showNextPage()
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
		guard comic != nil else { return }
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
		
		currentPage = page
		
		bottomToolbar.pageNumber = currentPage + 1
		
		pageChanged()
		renderCurrentPage()
		
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

	private func renderCurrentPage() {
		guard let comic = comic else { return }

		currentPageView.viewForZoom?.removeFromSuperview()
		currentPageView.viewForZoom = nil
		currentPageView.pageRect = .zero

		let scale = UIScreen.main.scale
		guard let img = comic.imageAtIndex(currentPage, screenSize: pagesView.bounds.size, scale: scale) else { return }

		let imageView = UIImageView(image: img)
		imageView.contentMode = .scaleAspectFit
		
		let pageRect = CGRect(origin: .zero, size: img.size)
		currentPageView.pageRect = pageRect
		imageView.frame = pageRect

		currentPageView.addSubview(imageView)
		currentPageView.viewForZoom = imageView
		currentPageView.contentSize = pageRect.size

		updateZoomParamsScaling(scaleWidth: shouldScalePageToWidth(for: pagesView.bounds.size))
		
		// Preload next page
		if currentPage + 1 < totalPages {
			let nextPage = currentPage + 1
			let size = pagesView.bounds.size
			Task.detached(priority: .background) {
				_ = comic.imageAtIndex(nextPage, screenSize: size, scale: scale)
			}
		}
	}

	private func refreshCurrentPageLayoutIfNeeded(for size: CGSize) {
		guard size != .zero else { return }
		guard lastPagesViewSize != size else { return }

		lastPagesViewSize = size

		guard comic != nil, currentPageView.pageRect != .zero else { return }

		renderCurrentPage()
		currentPageView.setNeedsLayout()
		currentPageView.layoutIfNeeded()
		currentPageView.layer.setNeedsDisplay()
		currentPageView.viewForZoom?.setNeedsLayout()
		currentPageView.viewForZoom?.layoutIfNeeded()
		currentPageView.viewForZoom?.layer.setNeedsDisplay()
	}

	private func shouldScalePageToWidth(for size: CGSize) -> Bool {
		if #available(iOS 14.0, *) {
			if traitCollection.userInterfaceIdiom == .mac {
				return false
			}
		}

		return UIDevice.current.userInterfaceIdiom != .pad && size.width > size.height
	}

	private func togglePanelsIfNeeded() {
		guard comic != nil else { return }
		toggleToolbars()
	}

	private func showPreviousPage() {
		displayPage(currentPage - 1, animationDirection: 1)
	}

	private func showNextPage() {
		displayPage(currentPage + 1, animationDirection: -1)
	}
	
	@objc private func handleSwipe(_ sender: UISwipeGestureRecognizer) {
		guard comic != nil else { return }
		guard sender.state == .recognized else { return }
		
		if sender.direction == .left {
			showNextPage()
		}
		else if sender.direction == .right {
			showPreviousPage()
		}
	}

	@objc private func handlePreviousPageKeyCommand() {
		showPreviousPage()
	}

	@objc private func handleNextPageKeyCommand() {
		showNextPage()
	}

	@objc private func handleTogglePanelsKeyCommand() {
		togglePanelsIfNeeded()
	}

	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer === swipeLeftRecognizer || gestureRecognizer === swipeRightRecognizer {
			return !currentPageView.isZoomedIn
		}

		return true
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
		if IS_MAC_CATALYST {
			switch SettingsStorage.instance.libraryDirectoryState() {
			case .notSelected:
				presentLibraryDirectorySetupIfNeeded()
				return
			case .unavailable(let url):
				presentLibraryDirectoryUnavailableAlert(for: url)
				return
			case .available:
				break
			}
		}

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
			let libraryDirectoryState = await MainActor.run { () -> LibraryDirectoryState in
				if IS_MAC_CATALYST {
					return SettingsStorage.instance.libraryDirectoryState()
				}
				return .available(URL(fileURLWithPath: DOCPATH, isDirectory: true))
			}

			switch libraryDirectoryState {
			case .available(let url):
				await LibraryDataSource.instance.updateLibrary(rootPath: url.path)
			case .notSelected:
				await LibraryDataSource.instance.clearLibrary()
				await MainActor.run {
					self.comic = nil
					self.presentLibraryDirectorySetupIfNeeded()
				}
			case .unavailable(let url):
				await LibraryDataSource.instance.clearLibrary()
				await MainActor.run {
					self.comic = nil
					self.presentLibraryDirectoryUnavailableAlert(for: url)
				}
			}
		}
	}

	func selectLibraryDirectory() {
		presentLibraryDirectoryPicker()
	}
}

extension ViewerViewController: UIAdaptivePresentationControllerDelegate {
	func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		if presentationController.presentedViewController is UIDocumentPickerViewController {
			libraryDirectoryPickerController = nil
		}
	}
}

extension ViewerViewController {
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		guard let url = urls.first else { return }

		libraryDirectoryPickerController = nil
		SettingsStorage.instance.saveLibraryDirectory(url)
		hasPresentedLibraryDirectoryPrompt = false
		hasPresentedLibraryDirectoryUnavailableAlert = false
		updateWindowHeader()
		forceUpdateLibrary()
	}

	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
		libraryDirectoryPickerController = nil
		SettingsStorage.instance.saveLibraryDirectory(url)
		hasPresentedLibraryDirectoryPrompt = false
		hasPresentedLibraryDirectoryUnavailableAlert = false
		updateWindowHeader()
		forceUpdateLibrary()
	}

	func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		libraryDirectoryPickerController = nil
		hasPresentedLibraryDirectoryPrompt = false
		hasPresentedLibraryDirectoryUnavailableAlert = false
	}
}
