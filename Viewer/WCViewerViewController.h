//
//  WCViewerViewController.h
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCSliderToolbar.h"

@class WCComic;

@interface WCViewerViewController : UIViewController <UIScrollViewDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) WCComic *comic;

- (void)dismissPopover;
- (void)comicRemoved:(NSDictionary *)item;

@end
