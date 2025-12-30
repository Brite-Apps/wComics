//
//  ScrollView.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import UIKit

class ScrollView: UIScrollView, UIScrollViewDelegate {
	weak var viewForZoom: UIView?
	var pageRect = CGRect.zero
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}
	
	private func setup() {
		autoresizingMask = [.flexibleWidth, .flexibleHeight]
		isScrollEnabled = true
		maximumZoomScale = 5.0
		delegate = self
		delaysContentTouches = false
		backgroundColor = .black
		showsVerticalScrollIndicator = false
		showsHorizontalScrollIndicator = false
	}
	
	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		let offsetX = max((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0)
		let offsetY = max((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0)

		viewForZoom?.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
	}
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return viewForZoom
	}
}
