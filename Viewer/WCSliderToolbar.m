//
//  WCSliderToolbar.m
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCSliderToolbar.h"

extern BOOL isPad;

@implementation WCSliderToolbar {
	UILabel *pageLabel;
	UISlider *slider;
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame]) != nil) {
		pageLabel = [[UILabel alloc] init];
		pageLabel.backgroundColor = [UIColor clearColor];
		pageLabel.numberOfLines = 1;
		pageLabel.font = [UIFont boldSystemFontOfSize:16];
		pageLabel.textColor = RGB(255, 255, 255);
		[self addSubview:pageLabel];
		
		slider = [[UISlider alloc] init];
		slider.minimumTrackTintColor = [UIColor darkGrayColor];
		slider.maximumTrackTintColor = [UIColor whiteColor];
		slider.continuous = NO;
		slider.minimumValue = 0.0f;
		slider.maximumValue = 1.0f;
		[slider sizeToFit];
		[slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
		[self addSubview:slider];
	}
	return self;
}

- (void)redrawFrames {
	float progress = ((float)_pageNumber - 1) / ((float)_totalPages - 1);

	if (_pageNumber == -1) {
		progress = 0.0f;
		pageLabel.text = nil;
	}
	
	slider.value = progress;
}

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	[self redrawFrames];
	
	[slider sizeToFit];
	frame = slider.bounds;
	frame.size.width = self.bounds.size.width - 20.0f * 2.0f;
	frame.origin.x = floorf((self.bounds.size.width - frame.size.width) * 0.5f);
	frame.origin.y = self.bounds.size.height - frame.size.height - 10.0f;
	slider.frame = frame;
}

- (void)setPageNumber:(NSInteger)p {
	_pageNumber = p;
	
	[self redrawFrames];

	if (_totalPages > 0) {
		NSString *format = isPad ? @"PAGE_X_OF_Y" : @"X_OF_Y";
		NSString *text = [[NSString alloc] initWithFormat:NSLocalizedString(format, @"Page %d / %d"), _pageNumber, _totalPages];
		pageLabel.text = text;
	}
	else {
		pageLabel.text = nil;
	}

	[pageLabel sizeToFit];
	
	CGRect frame = pageLabel.frame;
	frame.origin.x = floorf((self.bounds.size.width - frame.size.width) * 0.5f);
	frame.origin.y = floorf((self.bounds.size.height * 0.5f - frame.size.height) * 0.5f) - 2.0f;
	pageLabel.frame = frame;
	
	if (_pageNumber == -1) {
		pageLabel.hidden = YES;
		slider.enabled = NO;
	}
	else {
		pageLabel.hidden = NO;
		slider.enabled = YES;
	}
}

- (void)setTotalPages:(NSInteger)totalPages {
	_totalPages = totalPages;
	slider.maximumValue = 1.0f - (1.0f / (float)totalPages);
}

- (void)sliderValueChanged:(UISlider *)sender {
	[_target sliderValueChanged:sender.value];
}

@end
