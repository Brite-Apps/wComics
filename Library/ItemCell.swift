//
//  ItemCell.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import UIKit

class ItemCell: UICollectionViewCell {
	private var coverTask: Task<Void, Never>?
	private let imageView = UIImageView()
	private let titleLabel = UILabel()
	private let checkmarkView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
	private var gridConstraints = [NSLayoutConstraint]()
	private var listConstraints = [NSLayoutConstraint]()

	var presentationMode: LibraryPresentationMode = .grid {
		didSet {
			guard presentationMode != oldValue else { return }
			updateLayoutForPresentationMode()
		}
	}
	
	var item: ComicItem? {
		didSet {
			coverTask?.cancel()
			coverTask = nil
			
			if let item = item {
				let title = (item.path as NSString).lastPathComponent
				titleLabel.text = item.isDir ? title : (title as NSString).deletingPathExtension
				
				if item.isDir {
					imageView.image = UIImage(named: "folder")
					imageView.contentMode = .center
				}
				else {
					imageView.contentMode = .scaleAspectFill
					let coverFile = (COVERSPATH as NSString).appendingPathComponent("\((item.path as NSString).lastPathComponent)_wcomics_cover_file")
					
					if let data = try? Data(contentsOf: URL(fileURLWithPath: coverFile)), 
					   let cover = UIImage(data: data, scale: UIScreen.main.scale), cover.size.width > 0 {
						imageView.image = cover
					}
					else {
						imageView.image = UIImage(named: "document")
						imageView.contentMode = .center
						
						coverTask = Task {
							if let (image, _) = await Comic.createCoverImage(for: item.path) {
								await MainActor.run {
									self.imageView.image = image
									self.imageView.contentMode = .scaleAspectFill
								}
							}
						}
					}
				}
			}
		}
	}
	
	var isCurrent: Bool = false {
		didSet {
			checkmarkView.isHidden = !isCurrent
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}
	
	private func setup() {
		contentView.backgroundColor = .secondarySystemBackground
		contentView.layer.cornerRadius = 8
		contentView.layer.masksToBounds = true
		
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.clipsToBounds = true
		contentView.addSubview(imageView)
		
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
		titleLabel.textAlignment = .center
		titleLabel.numberOfLines = 2
		titleLabel.textColor = .label
		contentView.addSubview(titleLabel)
		
		checkmarkView.translatesAutoresizingMaskIntoConstraints = false
		checkmarkView.tintColor = .systemBlue
		checkmarkView.isHidden = true
		contentView.addSubview(checkmarkView)
		
		gridConstraints = [
			imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
			imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			imageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -4),
			titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
			titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
			titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
			titleLabel.heightAnchor.constraint(equalToConstant: 32),
			checkmarkView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
			checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
			checkmarkView.widthAnchor.constraint(equalToConstant: 20),
			checkmarkView.heightAnchor.constraint(equalToConstant: 20)
		]

		listConstraints = [
			imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
			imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
			imageView.widthAnchor.constraint(equalToConstant: 52),
			imageView.heightAnchor.constraint(equalToConstant: 68),
			titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
			titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
			titleLabel.trailingAnchor.constraint(equalTo: checkmarkView.leadingAnchor, constant: -12),
			checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
			checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
			checkmarkView.widthAnchor.constraint(equalToConstant: 20),
			checkmarkView.heightAnchor.constraint(equalToConstant: 20)
		]

		updateLayoutForPresentationMode()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		coverTask?.cancel()
		coverTask = nil
		imageView.image = nil
		titleLabel.text = nil
		isCurrent = false
	}

	private func updateLayoutForPresentationMode() {
		NSLayoutConstraint.deactivate(gridConstraints + listConstraints)

		switch presentationMode {
		case .grid:
			titleLabel.textAlignment = .center
			titleLabel.numberOfLines = 2
			NSLayoutConstraint.activate(gridConstraints)
		case .list:
			titleLabel.textAlignment = .left
			titleLabel.numberOfLines = 1
			NSLayoutConstraint.activate(listConstraints)
		}
	}
}
