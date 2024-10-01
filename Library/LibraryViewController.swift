//
//  LibraryViewController.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nik S Dyonin. All rights reserved.
//

import UIKit

protocol LibraryViewControllerDelegate: AnyObject {
	@MainActor func comicItemSelected(_ item: ComicItem)
	@MainActor func currentComic() -> Comic?
	@MainActor func comicRemoved(_ item: ComicItem)
}

class LibraryViewController: UITableViewController {
	weak var delegate: LibraryViewControllerDelegate?
	private let cellId = "cellId"
	private var dataSource: [ComicItem]
	
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
		
		let closeItem = UIBarButtonItem(title: "CLOSE".localized(), style: .done, target: self, action: #selector(close))
		
		navigationItem.rightBarButtonItem = closeItem
	}
	
	@objc private func close() {
		dismiss(animated: true)
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
			
			if dataSource.isEmpty {
				navigationController?.popViewController(animated: true)
			}
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
}
