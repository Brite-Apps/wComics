//
//  WCInfoViewController.m
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCInfoViewController.h"
#import "Common.h"

@import WebKit;

@implementation WCInfoViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
	configuration.dataDetectorTypes = WKDataDetectorTypeNone;
	
	WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
	webView.backgroundColor = RGB(255, 255, 255);
	webView.navigationDelegate = self;
	self.view = webView;

	NSString *htmlString = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"info" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
	[webView loadHTMLString:htmlString baseURL:nil];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
	NSURL *url = navigationAction.request.URL;
	
	if (url == nil) {
		decisionHandler(WKNavigationActionPolicyCancel);
	}
	
	NSString *scheme = url.scheme;
	
	if (EQUAL_STR(scheme, @"http") || EQUAL_STR(scheme, @"https") || EQUAL_STR(scheme, @"mailto")) {
		[UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
		decisionHandler(WKNavigationActionPolicyCancel);
		return;
	}
	
	decisionHandler(WKNavigationActionPolicyAllow);
}

@end
