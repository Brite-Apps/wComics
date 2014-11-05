//
//  WCSliderToolbar.h
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

@import UIKit;

@protocol WCSliderToolbarDelegate

- (void)sliderValueChanged:(float)value;

@end


@interface WCSliderToolbar : UIView

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic) NSInteger totalPages;
@property (nonatomic, weak) id<WCSliderToolbarDelegate> target;

@end
