/**
 * @class WCSliderToolbar
 * @author Nik S Dyonin <wolf.step@gmail.com>
 */

#import "WCSliderToolbar.h"
#import <QuartzCore/QuartzCore.h>

@implementation WCSliderToolbar

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame]) != nil) {
		pageLabel = [[UILabel alloc] init];
		pageLabel.backgroundColor = [UIColor clearColor];
		pageLabel.numberOfLines = 1;
		pageLabel.font = [UIFont boldSystemFontOfSize:16];
		pageLabel.textColor = RGB(255, 255, 255);
		[self addSubview:pageLabel];
		
		slider = [[UISlider alloc] initWithFrame:CGRectZero];
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
	
	CGRect tmpRect = slider.bounds;
	tmpRect.origin.x = 20.0f;
	tmpRect.size.width = frame.size.width - 20.0f * 2.0f;
	tmpRect.origin.y = frame.size.height - tmpRect.size.height - 10.0f;
	slider.frame = tmpRect;
}

- (void)setPageNumber:(NSInteger)p {
	_pageNumber = p;
	
	[self redrawFrames];

	NSString *text = [[NSString alloc] initWithFormat:NSLocalizedString(@"PAGE_X_OF_Y", @"Page %d / %d"), _pageNumber, _totalPages];
	pageLabel.text = text;
	
	[pageLabel sizeToFit];
	
	CGRect tmpRect = pageLabel.frame;
	tmpRect.origin.x = floorf((self.bounds.size.width - tmpRect.size.width) / 2.0f);
	tmpRect.origin.y = 5.0f;
	pageLabel.frame = tmpRect;
	
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
	@try {
		if ([_target respondsToSelector:_selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[_target performSelector:_selector withObject:@(sender.value)];
#pragma clang diagnostic pop
		}
	}
	@catch (NSException *exception) {
	}
}

@end
