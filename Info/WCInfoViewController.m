/**
 * @class WCInfoViewController
 * @author Nik Dyonin <wolf.step@gmail.com>
 */

#import "WCInfoViewController.h"

@implementation WCInfoViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
	webView.backgroundColor = RGB(255, 255, 255);
	self.view = webView;
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	webView.scalesPageToFit = YES;
	webView.delegate = self;
	
	NSString *htmlString = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"info" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
	[webView loadHTMLString:htmlString baseURL:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSString *scheme = [[request URL] scheme];
	
	if (EQUAL_STR(scheme, @"http") || EQUAL_STR(scheme, @"https") || EQUAL_STR(scheme, @"mailto")) {
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	}

	return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (BOOL)shouldAutorotate {
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}

- (void)dealloc {
	[webView stopLoading];
}

@end
