//
//  LibraryViewController.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

protocol LibraryViewControllerDelegate: AnyObject {
	@MainActor func comicItemSelected(_ item: ComicItem)
	@MainActor func currentComic() -> Comic?
	@MainActor func comicRemoved(_ item: ComicItem)
	@MainActor func forceUpdateLibrary()
	@MainActor func selectLibraryDirectory()
}

class LibraryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIDocumentPickerDelegate {
	weak var delegate: LibraryViewControllerDelegate?
	private let cellId = "cellId"
	private var dataSource: [ComicItem]
	private let showsLibraryRootActions: Bool
	private let emptyLabel = UILabel()
	private var collectionView: UICollectionView!
	private var presentationMode = SettingsStorage.instance.libraryPresentationMode
	private var presentationBarButtonItem: UIBarButtonItem?
	
	init(dataSource: [ComicItem], showsLibraryRootActions: Bool = false) {
		self.dataSource = dataSource
		self.showsLibraryRootActions = showsLibraryRootActions
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = .systemBackground
		preferredContentSize = CGSize(width: 600, height: 700)
		
		setupCollectionView()
		setupNavigation()
		setupEmptyLabel()
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleLibraryUpdated), name: LibraryDataSource.libraryUpdatedNotification, object: nil)
		
		reloadEmptyState()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if showsLibraryRootActions {
			dataSource = LibraryDataSource.instance.library
			reloadEmptyState()
		}

		collectionView.reloadData()
	}
	
	private func setupCollectionView() {
		collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		collectionView.backgroundColor = .clear
		collectionView.delegate = self
		collectionView.dataSource = self
		collectionView.register(ItemCell.self, forCellWithReuseIdentifier: cellId)
		
		view.addSubview(collectionView)
		collectionView.frame = view.bounds
	}
	
	private func setupNavigation() {
		let presentationItem = UIBarButtonItem(image: presentationToggleImage(), style: .plain, target: self, action: #selector(togglePresentationMode))
		presentationBarButtonItem = presentationItem

		if showsLibraryRootActions {
			if IS_MAC_CATALYST {
				let folderItem = UIBarButtonItem(image: UIImage(systemName: "folder"), style: .plain, target: self, action: #selector(selectLibraryDirectory))
				navigationItem.leftBarButtonItem = folderItem
			}
			else {
				let cloudItem = UIBarButtonItem(image: UIImage(systemName: "icloud"), style: .plain, target: self, action: #selector(pickFromCloud))
				navigationItem.leftBarButtonItem = cloudItem
			}
		}
		
		let closeItem = UIBarButtonItem(title: "CLOSE".localized(), style: .done, target: self, action: #selector(close))
		navigationItem.rightBarButtonItems = [closeItem, presentationItem]
	}
	
	private func setupEmptyLabel() {
		emptyLabel.text = "EMPTY_LIBRARY".localized()
		emptyLabel.translatesAutoresizingMaskIntoConstraints = false
		emptyLabel.backgroundColor = .clear
		emptyLabel.textColor = .lightGray
		emptyLabel.font = UIFont.preferredFont(forTextStyle: .headline)
		emptyLabel.lineBreakMode = .byWordWrapping
		emptyLabel.numberOfLines = 0
		emptyLabel.isHidden = true
		emptyLabel.textAlignment = .center
		
		view.addSubview(emptyLabel)
		
		NSLayoutConstraint.activate([
			emptyLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
			emptyLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
			emptyLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -64),
		])
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	@objc private func pickFromCloud() {
		var contentTypes: [UTType] = [.archive, .pdf, .zip]
		if let cbz = UTType(filenameExtension: "cbz", conformingTo: .zip) {
			contentTypes.append(cbz)
		}
		if let rar = UTType(filenameExtension: "rar", conformingTo: .archive) {
			contentTypes.append(rar)
		}

		let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
		documentPickerController.allowsMultipleSelection = false
		documentPickerController.delegate = self
		present(documentPickerController, animated: true)
	}
	
	@objc private func close() {
		dismiss(animated: true)
	}

	@objc private func togglePresentationMode() {
		presentationMode = presentationMode == .grid ? .list : .grid
		SettingsStorage.instance.libraryPresentationMode = presentationMode
		collectionView.setCollectionViewLayout(makeLayout(), animated: true)
		collectionView.reloadData()
		collectionView.visibleCells.compactMap { $0 as? ItemCell }.forEach { $0.presentationMode = presentationMode }
		presentationBarButtonItem?.image = presentationToggleImage()
	}

	@objc private func selectLibraryDirectory() {
		delegate?.selectLibraryDirectory()
	}

	@objc private func handleLibraryUpdated() {
		guard showsLibraryRootActions else { return }
		dataSource = LibraryDataSource.instance.library
		collectionView.reloadData()
		reloadEmptyState()
	}
	
	private func reloadEmptyState() {
		emptyLabel.isHidden = !dataSource.isEmpty
		collectionView.isHidden = dataSource.isEmpty
	}

	private func makeLayout() -> UICollectionViewLayout {
		UICollectionViewCompositionalLayout { (_, layoutEnvironment) -> NSCollectionLayoutSection? in
			let spacing: CGFloat = 16
			let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
			let item = NSCollectionLayoutItem(layoutSize: itemSize)

			let group: NSCollectionLayoutGroup
			switch self.presentationMode {
			case .grid:
				let columns: Int
				if layoutEnvironment.container.contentSize.width > 800 {
					columns = 5
				}
				else if layoutEnvironment.container.contentSize.width > 500 {
					columns = 3
				}
				else {
					columns = 2
				}

				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(200))
				group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columns)
				group.interItemSpacing = .fixed(spacing)
			case .list:
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(84))
				group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
			}

			let section = NSCollectionLayoutSection(group: group)
			section.interGroupSpacing = spacing
			section.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
			return section
		}
	}

	private func presentationToggleImage() -> UIImage? {
		switch presentationMode {
		case .grid:
			return UIImage(systemName: "list.bullet")
		case .list:
			return UIImage(systemName: "square.grid.2x2")
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return dataSource.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ItemCell
		let item = dataSource[indexPath.row]
		cell.presentationMode = presentationMode
		cell.item = item
		
		if !item.isDir {
			let currentComic = delegate?.currentComic()
			cell.isCurrent = (currentComic?.file as? NSString)?.resolvingSymlinksInPath == (item.path as NSString).resolvingSymlinksInPath
		}
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let item = dataSource[indexPath.row]
		
		if item.isDir {
			let v = LibraryViewController(dataSource: item.children)
			v.title = (item.path as NSString).lastPathComponent
			v.delegate = self.delegate
			navigationController?.pushViewController(v, animated: true)
		}
		else {
			delegate?.comicItemSelected(item)
		}
	}
	
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		guard let fileUrl = urls.first else { return }
		let destinationUrl = URL(fileURLWithPath: (DOCPATH as NSString).appendingPathComponent(fileUrl.lastPathComponent))
		
		do {
			if fileUrl.startAccessingSecurityScopedResource() {
				try FileManager.default.copyItem(at: fileUrl, to: destinationUrl)
				fileUrl.stopAccessingSecurityScopedResource()
				
				let item = ComicItem(path: destinationUrl.path, isDir: false)
				delegate?.comicItemSelected(item)
				delegate?.forceUpdateLibrary()
			}
			else {
				showErrorAlert(message: "YOU_DO_NOT_HAVE_ACCESS_TO_THIS_FILE".localized())
			}
		}
		catch {
			showErrorAlert(message: error.localizedDescription)
		}
	}
	
	private func showErrorAlert(message: String) {
		let alert = UIAlertController(title: "WARNING".localized(), message: "\("CANNOT_OPEN_FILE".localized()): \(message)", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK".localized(), style: .default))
		present(alert, animated: true)
	}
}
