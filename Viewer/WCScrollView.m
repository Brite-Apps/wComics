/**
 * @class WCScrollView
 * @author Nik S Dyonin <wolf.step@gmail.com>
 */

#import "WCScrollView.h"

@implementation WCScrollView

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame]) != nil) {
		self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		self.scrollEnabled = YES;
		self.maximumZoomScale = 100.0;
		self.delegate = self;
		self.delaysContentTouches = NO;
		self.backgroundColor = [UIColor clearColor];
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
	}
	return self;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	CGRect _innerFrame = _viewForZoom.frame;
	CGRect scrollerBounds = scrollView.bounds;

	if ((_innerFrame.size.width < scrollerBounds.size.width ) || (_innerFrame.size.height < scrollerBounds.size.height)) {
		CGFloat tempx = _viewForZoom.center.x - (scrollerBounds.size.width / 2.0);
		CGFloat tempy = _viewForZoom.center.y - (scrollerBounds.size.height / 2.0);
		CGPoint myScrollViewOffset = CGPointMake(tempx, tempy);
		
		self.contentOffset = myScrollViewOffset;
	}

	UIEdgeInsets anEdgeInset = {0, 0, 0, 0};
	if (scrollerBounds.size.width > _innerFrame.size.width) {
		anEdgeInset.left = (scrollerBounds.size.width - _innerFrame.size.width) / 2.0;
		anEdgeInset.right = - anEdgeInset.left;
	}
	if (scrollerBounds.size.height > _innerFrame.size.height) {
		anEdgeInset.top = (scrollerBounds.size.height - _innerFrame.size.height) / 2.0;
		anEdgeInset.bottom = -anEdgeInset.top;
	}
	
	self.contentInset = anEdgeInset;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return _viewForZoom;
}

@end
