/**
 * @class WCSliderToolbar
 */

@interface WCSliderToolbar : UIView {
	UILabel *pageLabelBlack;
	UILabel *pageLabelWhite;

	UIView *whiteProgress;
	UIView *blackProgress;
	
	BOOL processTouch;
}

@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, assign) NSInteger totalPages;

@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL selector;

@end
