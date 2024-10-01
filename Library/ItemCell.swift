//
//  ItemCell.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nik S Dyonin. All rights reserved.
//

import UIKit

class ItemCell: UITableViewCell {
	private var coverTask: Task<Void, Never>?
	
	var item: ComicItem? {
		didSet {
			coverTask?.cancel()
			coverTask = nil
			
			if let item = item {
				guard !item.isDir else {
					accessoryType = .disclosureIndicator
					imageView?.image = UIImage(named: "folder")

					return
				}
				
				accessoryType = .none
				
				let coverFile = "\(DOCPATH)/covers/\((item.path as NSString).lastPathComponent)_wcomics_cover_file"
				
				var hasCover = false
				
				if FileManager.default.fileExists(atPath: coverFile) {
					if let data = try? Data(contentsOf: URL(fileURLWithPath: coverFile)), let cover = UIImage(data: data, scale: UIScreen.main.scale), cover.size.width > 0 {
						imageView?.image = cover
						hasCover = true
					}
				}
				
				if !hasCover {
					imageView?.image = UIImage(named: "document")
					
					coverTask = Task {
						if let (image, path) = await Comic.createCoverImage(for: item.path) {
							if path == coverFile {
								await MainActor.run {
									imageView?.image = image
								}
							}
						}
					}
				}
				
				var title = (item.path as NSString).lastPathComponent
				
				if !item.isDir {
					title = (title as NSString).deletingPathExtension
				}
				
				textLabel?.text = title
			}
			
			setNeedsLayout()
		}
	}
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setup()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}
	
	private func setup() {
		textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
		textLabel?.lineBreakMode = .byTruncatingTail
		textLabel?.numberOfLines = 1
		
		imageView?.contentMode = .scaleAspectFit
		
		selectionStyle = .gray
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let xOffset = self.textLabel!.frame.origin.x - (self.imageView!.frame.origin.x + self.imageView!.bounds.size.width)
		
		var frame = self.imageView!.frame
		frame.size.width = 32.0
		
		self.imageView!.frame = frame
		
		frame = self.textLabel!.frame
		frame.origin.x = self.imageView!.frame.origin.x + self.imageView!.bounds.size.width + xOffset
		
		self.textLabel!.frame = frame
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()

		coverTask?.cancel()
		coverTask = nil
		
		imageView?.image = nil
		textLabel?.text = nil
	}
	
	deinit {
		coverTask?.cancel()
		coverTask = nil
	}
}
