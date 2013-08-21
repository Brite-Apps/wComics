/**
 * @class WCViewerViewController
 */

#import <QuartzCore/QuartzCore.h>
#import "WCSliderToolbar.h"

@class WCScrollView;

@interface WCViewerViewController : UIViewController <UIScrollViewDelegate, UIPopoverControllerDelegate> {
	UIScrollView *pagesScrollView;
	int currentPageNumber;
	int totalPagesNumber;

	BOOL animating;
	
	UIPopoverController *currentPopover;
	UINavigationController *navController;

	BOOL scaleWidth;
	
	UIView *topToolbar;
	WCSliderToolbar *bottomToolbar;
	
	UIButton *libraryButton;
	UIButton *wifiButton;
	UIButton *infoButton;
}

@property (nonatomic, strong) WCComic *comic;
@property (nonatomic, strong) UIView *updateIndicator;

- (void)redrawInterface;
- (void)displayPage:(int)pageNum;
- (void)updateZoomParams:(int)pageNum;
- (void)dismissPopover;
- (void)comicRemoved:(NSDictionary *)item;

@end
