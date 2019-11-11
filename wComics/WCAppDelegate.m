//
//  WCAppDelegate.m
//  wComics
//
//  Created by Nik Dyonin on 24.07.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCAppDelegate.h"
#import "WCViewerViewController.h"
#import "WCLibraryDataSource.h"
#import "WCComic.h"
#import "WCSettingsStorage.h"
#import "Common.h"

BOOL isPad;
NSOperationQueue *coversQueue;

@implementation WCAppDelegate {
	UIWindow *window;
	WCViewerViewController *viewController;
	BOOL justStarted;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
	
	coversQueue = [[NSOperationQueue alloc] init];
	coversQueue.maxConcurrentOperationCount = 1;

	viewController = [[WCViewerViewController alloc] init];
	
	window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
	window.rootViewController = viewController;

	[window makeKeyAndVisible];
	
	justStarted = YES;
	
	[self updateLibrary];
	
	return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
	if (url) {
		WCComic *comic = [[WCComic alloc] initWithFile:url.path];
		viewController.comic = comic;
	}
	
	return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	[[WCSettingsStorage sharedInstance] setLastDocument:viewController.comic.file];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	[self updateLibrary];
}

- (void)checkOpen {
	NSString *lastDocument = [[WCSettingsStorage sharedInstance] lastDocument];

	if (lastDocument) {
		WCComic *comic = [[WCComic alloc] initWithFile:lastDocument];
		viewController.comic = comic;
	}
	else {
		viewController.comic = nil;
	}
}

- (void)updateLibrary {
	__weak typeof(self) weakSelf = self;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		__strong __typeof(weakSelf) strongSelf = weakSelf;
		
		NSString *coverDir = [DOCPATH stringByAppendingPathComponent:@"covers"];
		[[NSFileManager defaultManager] createDirectoryAtPath:coverDir withIntermediateDirectories:YES attributes:nil error:nil];
		[[WCLibraryDataSource sharedInstance] updateLibrary];
		
		if (strongSelf->justStarted) {
			strongSelf->justStarted = NO;

			dispatch_async(dispatch_get_main_queue(), ^{
				[strongSelf checkOpen];
			});
		}
	});
}

@end
