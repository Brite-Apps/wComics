//
//  ScrollView.swift
//  wComics
//
//  Created by Nikita Denin on 30.09.24.
//  Copyright © 2024 Nikita Denin. All rights reserved.
//

import UIKit
#if targetEnvironment(macCatalyst)
import AppKit
#endif

class ScrollView: UIScrollView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
	weak var viewForZoom: UIView?
	var pageRect = CGRect.zero
	private var pinchStartZoomScale: CGFloat = 1.0
	private var pinchAnchorPoint = CGPoint.zero
	private var isPointerInside = false
	
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
		bouncesZoom = false
		delegate = self
		delaysContentTouches = false
		backgroundColor = .black
		showsVerticalScrollIndicator = false
		showsHorizontalScrollIndicator = false
		if IS_MAC_CATALYST {
			panGestureRecognizer.isEnabled = false
			pinchGestureRecognizer?.isEnabled = false

			let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
			pinchRecognizer.delegate = self
			addGestureRecognizer(pinchRecognizer)

			let wheelZoomRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleWheelZoom(_:)))
			wheelZoomRecognizer.allowedScrollTypesMask = .all
			wheelZoomRecognizer.allowedTouchTypes = []
			wheelZoomRecognizer.delegate = self
			addGestureRecognizer(wheelZoomRecognizer)

			let dragPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragPan(_:)))
			dragPanRecognizer.delegate = self
			addGestureRecognizer(dragPanRecognizer)

			let hoverRecognizer = UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:)))
			addGestureRecognizer(hoverRecognizer)
		}
	}
	
	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		let offsetX = max((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0)
		let offsetY = max((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0)

		viewForZoom?.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
	}
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return viewForZoom
	}

	var isZoomedIn: Bool {
		return zoomScale > minimumZoomScale + 0.01
	}

	override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		guard viewForZoom != nil else { return false }

		if gestureRecognizer is UIPinchGestureRecognizer {
			return true
		}

		if let panRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
			if panRecognizer.allowedScrollTypesMask == .all {
				return true
			}

			return isZoomedIn
		}

		return true
	}

	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer is UIPinchGestureRecognizer || otherGestureRecognizer is UIPinchGestureRecognizer {
			return false
		}

		return false
	}

	@objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
		guard viewForZoom != nil else { return }

		let location = recognizer.location(in: self)

		switch recognizer.state {
		case .began:
			pinchStartZoomScale = zoomScale
			pinchAnchorPoint = location
		case .changed:
			setZoomScaleAroundAnchor(pinchStartZoomScale * recognizer.scale, location: pinchAnchorPoint)
		default:
			break
		}
	}

	@objc private func handleWheelZoom(_ recognizer: UIPanGestureRecognizer) {
		guard viewForZoom != nil else { return }

		let translation = recognizer.translation(in: self)

		switch recognizer.state {
		case .began:
			pinchAnchorPoint = recognizer.location(in: self)
		case .changed:
			let delta = translation.y * 0.01
			if delta != 0 {
				let nextZoomScale = zoomScale * (1.0 + delta)
				setZoomScaleAroundAnchor(nextZoomScale, location: pinchAnchorPoint)
				recognizer.setTranslation(.zero, in: self)
			}
		default:
			break
		}
	}

	@objc private func handleDragPan(_ recognizer: UIPanGestureRecognizer) {
		guard isZoomedIn else { return }

		let translation = recognizer.translation(in: self)

		switch recognizer.state {
		case .began:
			updateCursor(1) // closedHand
		case .changed:
			let targetOffset = CGPoint(x: contentOffset.x - translation.x, y: contentOffset.y - translation.y)
			setContentOffset(clampedContentOffset(targetOffset), animated: false)
			recognizer.setTranslation(.zero, in: self)
		case .ended, .cancelled, .failed:
			updateCursor()
		default:
			break
		}
	}

	@objc private func handleHover(_ recognizer: UIHoverGestureRecognizer) {
		switch recognizer.state {
		case .began, .changed:
			isPointerInside = true
			updateCursor()
		case .ended, .cancelled:
			isPointerInside = false
			updateCursor()
		default:
			break
		}
	}

	private func setZoomScaleAroundAnchor(_ scale: CGFloat, location: CGPoint) {
		let clampedScale = min(max(scale, minimumZoomScale), maximumZoomScale)
		guard clampedScale != zoomScale else { return }

		let anchorPoint = CGPoint(
			x: (contentOffset.x + location.x) / zoomScale,
			y: (contentOffset.y + location.y) / zoomScale
		)

		super.setZoomScale(clampedScale, animated: false)
		scrollViewDidZoom(self)

		let targetOffset = CGPoint(
			x: anchorPoint.x * clampedScale - location.x,
			y: anchorPoint.y * clampedScale - location.y
		)

		setContentOffset(clampedContentOffset(targetOffset), animated: false)
		updateCursor()
	}

	private func clampedContentOffset(_ offset: CGPoint) -> CGPoint {
		let maxOffsetX = max(contentSize.width - bounds.width, 0)
		let maxOffsetY = max(contentSize.height - bounds.height, 0)

		return CGPoint(
			x: min(max(offset.x, 0), maxOffsetX),
			y: min(max(offset.y, 0), maxOffsetY)
		)
	}

	private func updateCursor() {
		#if targetEnvironment(macCatalyst)
		let cursor: NSCursor
		if isZoomedIn && isPointerInside {
			cursor = .openHand
		} else {
			cursor = .arrow
		}
		cursor.set()
		#endif
	}

	private func updateCursor(_ cursorType: Int) {
		#if targetEnvironment(macCatalyst)
		let cursor: NSCursor
		if cursorType == 1 {
			cursor = .closedHand
		} else if cursorType == 2 {
			cursor = .openHand
		} else {
			cursor = .arrow
		}
		cursor.set()
		#endif
	}
}
