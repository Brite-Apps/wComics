//
//  WCScrollView.m
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCScrollView.h"
#import "Common.h"

@implementation WCScrollView

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame]) != nil) {
		self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		self.scrollEnabled = YES;
		self.maximumZoomScale = 5.0f;
		self.delegate = self;
		self.delaysContentTouches = NO;
		self.backgroundColor = RGB(0, 0, 0);
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
	}
	return self;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	CGFloat offsetX = MAX((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5f, 0.0f);
	CGFloat offsetY = MAX((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5f, 0.0f);
	_viewForZoom.center = CGPointMake(scrollView.contentSize.width * 0.5f + offsetX, scrollView.contentSize.height * 0.5f + offsetY);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return _viewForZoom;
}

@end
