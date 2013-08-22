/**
 * @class WCSliderToolbar
 */

@interface WCSliderToolbar : UIView {
	UILabel *pageLabel;
	UISlider *slider;
}

@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, assign) NSInteger totalPages;
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL selector;

@end
