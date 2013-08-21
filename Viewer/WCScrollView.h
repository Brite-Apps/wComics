/**
 * @class WCScrollView
 */

@interface WCScrollView : UIScrollView <UIScrollViewDelegate> {
	CGPoint startTouchPoint;
}

@property (nonatomic, assign) UIView *viewForZoom;
@property (nonatomic, assign) CGRect pageRect;

@end
