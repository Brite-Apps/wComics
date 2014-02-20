//
//  WCAppDelegate.h
//  wComics
//
//  Created by Nik Dyonin on 24.07.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

@class WCViewerViewController;

@interface WCAppDelegate : UIResponder <UIApplicationDelegate> {
	UIWindow *window;
	WCViewerViewController *viewController;
	UIView *updateIndicator;
	BOOL justStarted;
}

- (void)showIndicator;
- (void)updateLibrary;

@end
