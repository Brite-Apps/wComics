//
//  WCServerViewController.m
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCServerViewController.h"
#import "GCDWebUploader.h"
#import "Common.h"

extern BOOL isPad;

@implementation WCServerViewController {
	GCDWebUploader *webUploader;
	UILabel *urlLabel;
	UIImageView *wifiImageView;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	wifiImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wifi-big-image"]];
	[self.view addSubview:wifiImageView];
	
	urlLabel = [[UILabel alloc] init];
	urlLabel.backgroundColor = [UIColor clearColor];
	urlLabel.numberOfLines = 3;
	urlLabel.textColor = RGB(0, 0, 0);
	urlLabel.font = [UIFont boldSystemFontOfSize:24];
	urlLabel.textAlignment = NSTextAlignmentCenter;
	
	webUploader = [[GCDWebUploader alloc] initWithUploadDirectory:DOCPATH];
	[webUploader start];

	NSString *addr = [[NSString alloc] initWithFormat:NSLocalizedString(@"UPLOAD_STRING", @""), webUploader.serverURL];
	urlLabel.text = addr;

	[urlLabel sizeToFit];
	
	[self.view addSubview:urlLabel];
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self redrawInterface];
}

- (void)redrawInterface {
	if (!isPad && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
		wifiImageView.hidden = YES;
		
		CGRect frame = urlLabel.frame;
		frame.origin.x = floorf((self.view.bounds.size.width - frame.size.width) * 0.5f);
		frame.origin.y = floorf((self.view.bounds.size.height - frame.size.height) * 0.5f);
		urlLabel.frame = frame;
	}
	else {
		wifiImageView.hidden = NO;
		
		CGRect frame = wifiImageView.bounds;
		frame.origin.x = floorf((self.view.bounds.size.width - frame.size.width) * 0.5f);
		frame.origin.y = isPad ? 80.0f : 100.0f;
		wifiImageView.frame = frame;
		
		frame = urlLabel.frame;
		frame.origin.x = floorf((self.view.bounds.size.width - frame.size.width) * 0.5f);
		frame.origin.y = wifiImageView.frame.origin.y + wifiImageView.bounds.size.height + 50.0f;
		urlLabel.frame = frame;
	}
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[self redrawInterface];
}

- (NSUInteger)supportedInterfaceOrientations {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
	}
	
	return UIInterfaceOrientationMaskAll;
}

- (void)dealloc {
	[webUploader stop];
	webUploader = nil;
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

@end
