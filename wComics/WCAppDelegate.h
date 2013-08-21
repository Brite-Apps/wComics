//
//  WCAppDelegate.h
//  wComics
//
//  Created by Nik S Dyonin on 24.07.13.
//  Copyright (c) 2013 Brite Apps. All rights reserved.
//

@class WCViewerViewController;

@interface WCAppDelegate : UIResponder <UIApplicationDelegate> {
	UIWindow *window;
	WCViewerViewController *viewController;
	UIView *updateIndicator;
	BOOL justStarted;
}

- (void)showIndicator;

@end
