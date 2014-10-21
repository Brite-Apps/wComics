//
//  WCViewerViewController.h
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCSliderToolbar.h"
#import "WCLibraryViewController.h"

@class WCComic;

@interface WCViewerViewController : UIViewController <UIScrollViewDelegate, WCSliderToolbarDelegate, WCLibraryViewControllerDelegate>

@property (nonatomic, strong) WCComic *comic;

- (void)comicRemoved:(NSDictionary *)item;

@end
