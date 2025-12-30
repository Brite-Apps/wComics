//
//  SliderToolbar.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import UIKit

protocol SliderToolbarDelegate: AnyObject {
	@MainActor
	func sliderValueChanged(value: Float)
}

class SliderToolbar: UIView {
	private let pageLabel = UILabel()
	private let slider = UISlider()
	weak var delegate: SliderToolbarDelegate?
	
	var pageNumber = 0 {
		didSet {
			redrawSlider()
			
			if totalPages > 0 {
				pageLabel.text = "\(pageNumber) / \(totalPages)"
			}
			else {
				pageLabel.text = nil
			}
			
			if pageNumber == -1 {
				pageLabel.isHidden = true
				slider.isEnabled = false
			}
			else {
				pageLabel.isHidden = false
				slider.isEnabled = true
			}
		}
	}
	
	var totalPages = 0 {
		didSet {
			redrawSlider()
			slider.maximumValue = 1.0 - (1.0 / Float(totalPages))
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
		pageLabel.backgroundColor = .clear
		pageLabel.numberOfLines = 1
		pageLabel.font = UIFont.preferredFont(forTextStyle: .body)
		pageLabel.textColor = .white
		pageLabel.textAlignment = .center
		pageLabel.translatesAutoresizingMaskIntoConstraints = false
		
		addSubview(pageLabel)

		slider.minimumTrackTintColor = .darkGray
		slider.maximumTrackTintColor = .white
		slider.isContinuous = false
		slider.minimumValue = 0
		slider.maximumValue = 1
		slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
		slider.translatesAutoresizingMaskIntoConstraints = false
		
		addSubview(slider)
		
		NSLayoutConstraint.activate([
			slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
			slider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
			slider.topAnchor.constraint(equalTo: topAnchor),
			
			pageLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
			pageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
			pageLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
		])
	}
	
	@objc private func sliderValueChanged() {
		delegate?.sliderValueChanged(value: slider.value)
	}
	
	private func redrawSlider() {
		var progress: Float
		
		if totalPages - 1 == 0 {
			progress = 0
		}
		else {
			progress = (Float)(pageNumber - 1) / (Float)(totalPages - 1)
		}
		
		if pageNumber == -1 {
			progress = 0.0
			pageLabel.text = nil
		}
		
		slider.value = progress
	}
}
