//
//  LibraryViewController.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

protocol LibraryViewControllerDelegate: AnyObject {
	@MainActor func comicItemSelected(_ item: ComicItem)
	@MainActor func currentComic() -> Comic?
	@MainActor func comicRemoved(_ item: ComicItem)
	@MainActor func forceUpdateLibrary()
}

class LibraryViewController: UITableViewController, UIDocumentPickerDelegate {
	weak var delegate: LibraryViewControllerDelegate?
	private let cellId = "cellId"
	private var dataSource: [ComicItem]
	private let emptyLabel = UILabel()
	
	init(dataSource: [ComicItem]) {
		self.dataSource = dataSource
		super.init(style: .plain)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		preferredContentSize = CGSize(width: 600, height: 700)
		
		let cloudItem = UIBarButtonItem(image: UIImage(systemName: "icloud"), style: .plain, target: self, action: #selector(pickFromCloud))
		navigationItem.leftBarButtonItem = cloudItem
		
		let closeItem = UIBarButtonItem(title: "CLOSE".localized(), style: .done, target: self, action: #selector(close))
		navigationItem.rightBarButtonItem = closeItem
		
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
		
		reloadEmptyState()
	}
	
	@objc private func pickFromCloud() {
		var contentTypes = [UTType]()
		contentTypes.append(.archive)
		contentTypes.append(.pdf)
		contentTypes.append(.zip)
		
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
	
	private func reloadEmptyState() {
		emptyLabel.isHidden = !dataSource.isEmpty
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as? ItemCell ?? ItemCell(style: .default, reuseIdentifier: cellId)
		
		let item = dataSource[indexPath.row]
		
		cell.item = item

		let currentComic = delegate?.currentComic()
		
		if !item.isDir {
			if (currentComic?.file as? NSString)?.resolvingSymlinksInPath == (item.path as NSString).resolvingSymlinksInPath {
				cell.accessoryType = .checkmark
			}
			else {
				cell.accessoryType = .none
			}
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			let item = dataSource[indexPath.row]
			
			delegate?.comicRemoved(item)
			
			SettingsStorage.instance.removeSettings(for: item.path)
			
			let coverFile = "\(DOCPATH)/covers/\((item.path as NSString).lastPathComponent)_wcomics_cover_file"
			
			try? FileManager.default.removeItem(atPath: coverFile)
			try? FileManager.default.removeItem(atPath: item.path)

			dataSource.remove(at: indexPath.row)
			
			tableView.deleteRows(at: [indexPath], with: .fade)
			
			reloadEmptyState()
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
			try FileManager.default.copyItem(at: fileUrl, to: destinationUrl)
			let item = ComicItem(path: destinationUrl.path, isDir: false)
			delegate?.comicItemSelected(item)
			delegate?.forceUpdateLibrary()
		}
		catch {
			let alert = UIAlertController(title: "WARNING".localized(), message: "\("CANNOT_OPEN_FILE".localized()): \(error.localizedDescription)", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK".localized(), style: .default))
			present(alert, animated: true)
		}
	}
}
