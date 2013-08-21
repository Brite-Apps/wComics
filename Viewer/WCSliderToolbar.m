/**
 * @class WCSliderToolbar
 * @author Nik S Dyonin <nik@brite-apps.com>
 */

#import "WCSliderToolbar.h"
#import <QuartzCore/QuartzCore.h>

@implementation WCSliderToolbar

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame]) != nil) {
		whiteProgress = [[UIView alloc] init];
		whiteProgress.backgroundColor = RGBA(255, 255, 255, 0.8f);
		[self addSubview:whiteProgress];
		whiteProgress.layer.masksToBounds = YES;
		
		blackProgress = [[UIView alloc] init];
		blackProgress.backgroundColor = RGBA(0, 0, 0, 0.8f);
		[self addSubview:blackProgress];
		blackProgress.layer.masksToBounds = YES;
		
		pageLabelWhite = [[UILabel alloc] init];
		pageLabelWhite.backgroundColor = [UIColor clearColor];
		pageLabelWhite.numberOfLines = 1;
		pageLabelWhite.font = [UIFont boldSystemFontOfSize:18];
		pageLabelWhite.textColor = RGB(255, 255, 255);
		[blackProgress addSubview:pageLabelWhite];
		
		pageLabelBlack = [[UILabel alloc] init];
		pageLabelBlack.backgroundColor = [UIColor clearColor];
		pageLabelBlack.numberOfLines = 1;
		pageLabelBlack.font = [UIFont boldSystemFontOfSize:18];
		pageLabelBlack.textColor = RGB(0, 0, 0);
		[whiteProgress addSubview:pageLabelBlack];
	}
	return self;
}

- (void)redrawFrames {
	CGRect tmpRect = self.frame;
	float progress = ((float)_pageNumber - 1) / ((float)_totalPages - 1);
	if (_pageNumber == -1) {
		progress = 0;
		pageLabelBlack.text = nil;
		pageLabelWhite.text = nil;
	}
	tmpRect.origin = CGPointZero;
	tmpRect.size.width = self.frame.size.width * progress;
	whiteProgress.frame = CGRectIntegral(tmpRect);

	tmpRect.size.width = self.frame.size.width - whiteProgress.frame.size.width;
	tmpRect.origin.x = whiteProgress.frame.size.width;
	blackProgress.frame = CGRectIntegral(tmpRect);
}

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	[self redrawFrames];
}

- (void)setPageNumber:(NSInteger)p {
	_pageNumber = p;
	
	[self redrawFrames];

	NSString *text = [[NSString alloc] initWithFormat:NSLocalizedString(@"PAGE_X_OF_Y", @"Page %d / %d"), _pageNumber, _totalPages];
	pageLabelBlack.text = pageLabelWhite.text = text;
	
	[pageLabelBlack sizeToFit], [pageLabelWhite sizeToFit];
	
	CGRect tmpRect = pageLabelBlack.frame;
	tmpRect.origin.x = floorf((self.frame.size.width - tmpRect.size.width) / 2.0f);
	tmpRect.origin.y = floorf((self.frame.size.height - tmpRect.size.height) / 2.0f);
	pageLabelBlack.frame = tmpRect;

	tmpRect.origin.x = pageLabelBlack.frame.origin.x - blackProgress.frame.origin.x;
	pageLabelWhite.frame = tmpRect;

	if (_pageNumber == -1) {
		pageLabelBlack.text = nil;
		pageLabelWhite.text = nil;
	}
}

- (void)changeProgress:(float)progress {
	CGRect tmpRect = self.frame;
	tmpRect.origin = CGPointZero;
	tmpRect.size.width = self.frame.size.width * progress;
	whiteProgress.frame = CGRectIntegral(tmpRect);

	tmpRect.size.width = self.frame.size.width - whiteProgress.frame.size.width;
	tmpRect.origin.x = whiteProgress.frame.size.width;
	blackProgress.frame = CGRectIntegral(tmpRect);
	
	NSInteger pNum = _totalPages * progress + 1;
	
	NSString *text = [[NSString alloc] initWithFormat:NSLocalizedString(@"PAGE_X_OF_Y", @"Page %d / %d"), pNum, _totalPages];
	pageLabelBlack.text = pageLabelWhite.text = text;
	
	[pageLabelBlack sizeToFit], [pageLabelWhite sizeToFit];
	
	tmpRect = pageLabelBlack.frame;
	tmpRect.origin.x = floorf((self.frame.size.width - tmpRect.size.width) / 2.0f);
	tmpRect.origin.y = floorf((self.frame.size.height - tmpRect.size.height) / 2.0f);
	pageLabelBlack.frame = tmpRect;
	
	tmpRect.origin.x = pageLabelBlack.frame.origin.x - blackProgress.frame.origin.x;
	pageLabelWhite.frame = tmpRect;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	processTouch = YES;
	UITouch *touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];
	float progress = p.x / self.frame.size.width;
	[self changeProgress:progress];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (processTouch) {
		UITouch *touch = [touches anyObject];
		CGPoint p = [touch locationInView:self];
		float progress = p.x / self.frame.size.width;
		[self changeProgress:progress];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (processTouch) {
		UITouch *touch = [touches anyObject];
		CGPoint p = [touch locationInView:self];
		float progress = p.x / self.frame.size.width;

		@try {
			if ([_target respondsToSelector:_selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
				[_target performSelector:_selector withObject:@(progress)];
#pragma clang diagnostic pop
			}
		}
		@catch (NSException *exception) {
		}
	}
	processTouch = NO;
}

@end
