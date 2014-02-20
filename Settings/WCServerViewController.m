/**
 * @class WCServerViewController
 * @author Nik Dyonin <wolf.step@gmail.com>
 */

#import "WCServerViewController.h"
#import "FtpServer.h"
#import "NetworkController.h"

#define FTP_PORT 12345


@implementation WCServerViewController

- (void)redrawInterface {
	CGRect frame = urlLabel.frame;
	frame.origin.x = floorf((self.view.bounds.size.width - frame.size.width) * 0.5f);
	frame.origin.y = 426.0f;
	urlLabel.frame = frame;

	frame = wifiImageView.bounds;
	frame.origin.x = floorf((self.view.bounds.size.width - frame.size.width) * 0.5f);
	frame.origin.y = 80.0f;
	wifiImageView.frame = frame;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self redrawInterface];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	wifiImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wifi-big-image"]];
	[self.view addSubview:wifiImageView];

	NSString *localIPAddress = [NetworkController localWifiIPAddress];
	
	urlLabel = [[UILabel alloc] init];
	urlLabel.backgroundColor = [UIColor clearColor];
	urlLabel.numberOfLines = 3;
	urlLabel.textColor = RGB(0, 0, 0);
	urlLabel.font = [UIFont boldSystemFontOfSize:24];
	urlLabel.textAlignment = NSTextAlignmentCenter;

	if (!EQUAL_STR(localIPAddress, @"error")) {
		ftpServer = [[FtpServer alloc] initWithPort:FTP_PORT withDir:DOCPATH notifyObject:nil];
		NSString *addr = [[NSString alloc] initWithFormat:NSLocalizedString(@"UPLOAD_STRING", @""), localIPAddress, FTP_PORT];
		urlLabel.text = addr;
		
	}
	else {
		urlLabel.text = NSLocalizedString(@"ERROR_STARTING_SERVER", @"");
	}
	[urlLabel sizeToFit];
	
	[self.view addSubview:urlLabel];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[self redrawInterface];
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
	[ftpServer stopFtpServer];
	ftpServer = nil;
}

@end
