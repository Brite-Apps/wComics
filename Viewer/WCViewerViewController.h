/**
 * @class WCViewerViewController
 */

@import QuartzCore;
#import "WCSliderToolbar.h"

@class WCScrollView;
@class WCComic;

@interface WCViewerViewController : UIViewController <UIScrollViewDelegate, UIPopoverControllerDelegate> {
	UIScrollView *pagesScrollView;
	NSInteger currentPageNumber;
	NSInteger totalPagesNumber;

	BOOL animating;
	
	UIPopoverController *currentPopover;
	UINavigationController *navController;

	BOOL scaleWidth;

	UILabel *topLabel;
	__block WCSliderToolbar *bottomToolbar;
	
	UIButton *libraryButton;
	UIButton *wifiButton;
	UIButton *infoButton;
	
	BOOL toolbarHidden;
}

@property (nonatomic, strong) WCComic *comic;
@property (nonatomic, strong) UIView *updateIndicator;

- (void)dismissPopover;
- (void)comicRemoved:(NSDictionary *)item;

@end
