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
	urlLabel.numberOfLines = 0;
	urlLabel.lineBreakMode = NSLineBreakByWordWrapping;
	urlLabel.textColor = RGB(0, 0, 0);
	urlLabel.font = [UIFont boldSystemFontOfSize:24];
	urlLabel.textAlignment = NSTextAlignmentCenter;
	
	webUploader = [[GCDWebUploader alloc] initWithUploadDirectory:DOCPATH];
	[webUploader start];

	NSString *addr = [[NSString alloc] initWithFormat:NSLocalizedString(@"UPLOAD_STRING", @""), webUploader.serverURL];
	urlLabel.text = addr;
	
	[self.view addSubview:urlLabel];
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	if (!isPad && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
		wifiImageView.hidden = YES;

		CGRect frame = [urlLabel.text boundingRectWithSize:CGSizeMake(self.view.bounds.size.width, FLT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: urlLabel.font} context:nil];
		frame.origin.x = floor((self.view.bounds.size.width - frame.size.width) * 0.5);
		frame.origin.y = floor((self.view.bounds.size.height - frame.size.height) * 0.5);
		urlLabel.frame = frame;
	}
	else {
		wifiImageView.hidden = NO;
		
		CGRect frame = wifiImageView.bounds;
		frame.origin.x = floor((self.view.bounds.size.width - frame.size.width) * 0.5);
		frame.origin.y = isPad ? 80.0 : 100.0;
		wifiImageView.frame = frame;
		
		frame = [urlLabel.text boundingRectWithSize:CGSizeMake(self.view.bounds.size.width, FLT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: urlLabel.font} context:nil];
		frame.origin.x = floor((self.view.bounds.size.width - frame.size.width) * 0.5);
		frame.origin.y = wifiImageView.frame.origin.y + wifiImageView.bounds.size.height + 50.0;
		urlLabel.frame = frame;
	}
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
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
