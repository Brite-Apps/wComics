//
//  WCViewerViewController.m
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCViewerViewController.h"
#import "WCScrollView.h"
#import "WCLibraryViewController.h"
#import "WCServerViewController.h"
#import "WCInfoViewController.h"
#import "WCAppDelegate.h"
#import "WCComic.h"
#import "WCSettingsStorage.h"
#import "WCLibraryDataSource.h"
#import "Common.h"

extern BOOL isPad;

@implementation WCViewerViewController {
	UIView *pagesView;
	WCScrollView *currentPageView;
	
	NSInteger currentPageNumber;
	NSInteger totalPagesNumber;
	
	BOOL animating;

	UILabel *topLabel;
	WCSliderToolbar *bottomToolbar;
	
	UIButton *libraryButton;
	UIButton *wifiButton;
	UIButton *infoButton;
	
	BOOL toolbarHidden;
	
	UINavigationController *libraryNavigationController;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.view.backgroundColor = RGB(0, 0, 0);

	toolbarHidden = YES;
	
	CGRect frame;
	frame.origin.x = 0;
	frame.origin.y = self.view.bounds.size.height;
	frame.size.width = self.view.bounds.size.width;
	frame.size.height = 100;
	
	bottomToolbar = [[WCSliderToolbar alloc] initWithFrame:frame];
	bottomToolbar.backgroundColor = RGBA(0, 0, 0, 0.8);
	bottomToolbar.target = self;
	[self.view addSubview:bottomToolbar];
	
	frame.size.height = 44;
	frame.origin.y = -frame.size.height;
	
	topLabel = [[UILabel alloc] initWithFrame:frame];
	topLabel.backgroundColor = bottomToolbar.backgroundColor;
	topLabel.numberOfLines = 1;
	topLabel.font = [UIFont boldSystemFontOfSize:16];
	topLabel.textColor = RGB(255, 255, 255);
	topLabel.textAlignment = NSTextAlignmentCenter;
	topLabel.text = @"wComics";
	[self.view addSubview:topLabel];
	
	libraryButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[libraryButton setBackgroundImage:[UIImage imageNamed:@"library"] forState:UIControlStateNormal];
	[libraryButton sizeToFit];
	[bottomToolbar addSubview:libraryButton];
	[libraryButton addTarget:self action:@selector(showLibrary) forControlEvents:UIControlEventTouchUpInside];
	
	wifiButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[wifiButton setBackgroundImage:[UIImage imageNamed:@"wifi"] forState:UIControlStateNormal];
	[wifiButton sizeToFit];
	[bottomToolbar addSubview:wifiButton];
	[wifiButton addTarget:self action:@selector(showServerViewController:) forControlEvents:UIControlEventTouchUpInside];
	
	infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[infoButton setBackgroundImage:[UIImage imageNamed:@"info"] forState:UIControlStateNormal];
	[infoButton sizeToFit];
	[bottomToolbar addSubview:infoButton];
	[infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
	
	bottomToolbar.pageNumber = -1;
	
	pagesView = [[UIView alloc] initWithFrame:self.view.bounds];
	[self.view insertSubview:pagesView belowSubview:bottomToolbar];
	
	currentPageView = [[WCScrollView alloc] initWithFrame:pagesView.bounds];
	[pagesView addSubview:currentPageView];

	UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapRecognizer.numberOfTapsRequired = 2;
	[pagesView addGestureRecognizer:doubleTapRecognizer];
	
	UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	singleTapRecognizer.numberOfTapsRequired = 1;
	[singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
	[pagesView addGestureRecognizer:singleTapRecognizer];
	
	UISwipeGestureRecognizer *swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
	swipeLeftRecognizer.numberOfTouchesRequired = 1;
	swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
	[pagesView addGestureRecognizer:swipeLeftRecognizer];
	
	UISwipeGestureRecognizer *swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
	swipeRightRecognizer.numberOfTouchesRequired = 1;
	swipeRightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
	[pagesView addGestureRecognizer:swipeRightRecognizer];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self redrawInterfaceWithSize:self.view.bounds.size];
}

- (void)showErrorAlert {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"WARNING", @"Warning alert title") message:NSLocalizedString(@"CANNOT_OPEN_FILE", @"Cannot open file") preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}]];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)setComic:(WCComic *)aComic {
	if (aComic == nil) {
		[_comic close];
		_comic = nil;
		[[WCSettingsStorage sharedInstance] setLastDocument:nil];
		bottomToolbar.pageNumber = -1;
		topLabel.text = nil;
		
		topLabel.text = @"wComics";
		
		if (toolbarHidden) {
			[self toggleToolbars];
		}

		[currentPageView.viewForZoom removeFromSuperview];
		currentPageView.viewForZoom = nil;
	}
	else {
		if (![_comic isEqual:aComic]) {
			if (![[NSFileManager defaultManager] fileExistsAtPath:aComic.file isDirectory:NULL]) {
				[self showErrorAlert];
				return;
			}

			if (self.comic) {
				[[WCSettingsStorage sharedInstance] saveCurrentPage:currentPageNumber forFile:self.comic.file];
			}

			currentPageNumber = [[WCSettingsStorage sharedInstance] currentPageForFile:aComic.file];
			totalPagesNumber = aComic.numberOfPages;

			bottomToolbar.pageNumber = currentPageNumber + 1;
			bottomToolbar.totalPages = totalPagesNumber;

			[self.comic close];
			_comic = aComic;

			[[WCSettingsStorage sharedInstance] setLastDocument:self.comic.file];

			topLabel.text = self.comic.title;

			[currentPageView.viewForZoom removeFromSuperview];
			currentPageView.viewForZoom = nil;

			[self displayPage:currentPageNumber animationDirection:0];
		}
	}
}

- (void)showInfo {
	WCInfoViewController *v = [[WCInfoViewController alloc] init];
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:v];

	v.title = NSLocalizedString(@"INFO_TITLE", @"Information");
	nav.modalPresentationStyle = UIModalPresentationFormSheet;
	nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

	UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CLOSE", @"Close") style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewController)];
	v.navigationItem.rightBarButtonItem = closeItem;
	
	[self presentViewController:nav animated:YES completion:NULL];
}

- (void)dismissModalViewController {
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)comicItemSelected:(NSDictionary *)item {
	__weak typeof(self) weakSelf = self;
	
	[self dismissViewControllerAnimated:YES completion:^{
		if (!EQUAL_STR([item[@"path"] stringByResolvingSymlinksInPath], [weakSelf.comic.file stringByResolvingSymlinksInPath])) {
			WCComic *newComic = [[WCComic alloc] initWithFile:item[@"path"]];
			
			if (newComic) {
				weakSelf.comic = newComic;
			}
		}
	}];
}

- (void)showLibrary {
	if (!libraryNavigationController) {
		WCLibraryViewController *libraryViewController = [[WCLibraryViewController alloc] initWithStyle:UITableViewStylePlain];
		libraryViewController.dataSource = [WCLibraryDataSource sharedInstance].library;
		libraryViewController.title = NSLocalizedString(@"LIBRARY", @"Library");
		libraryViewController.target = self;
		libraryNavigationController = [[UINavigationController alloc] initWithRootViewController:libraryViewController];
		libraryNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	
	[self presentViewController:libraryNavigationController animated:YES completion:NULL];
}

- (void)hideServerViewController:(UIBarButtonItem *)sender {
	[self dismissViewControllerAnimated:YES completion:NULL];
	[(WCAppDelegate *)[UIApplication sharedApplication].delegate updateLibrary];
}

- (void)showServerViewController:(UIBarButtonItem *)sender {
	WCServerViewController *v = [[WCServerViewController alloc] init];
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:v];

	v.title = NSLocalizedString(@"SERVER_TITLE", @"Server");
	nav.modalPresentationStyle = UIModalPresentationFormSheet;
	nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

	UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"STOP_SERVER", @"Stop server") style:UIBarButtonItemStyleDone target:self action:@selector(hideServerViewController:)];
	v.navigationItem.rightBarButtonItem = closeItem;
	
	[self presentViewController:nav animated:YES completion:NULL];
}

- (void)handleDoubleTap:(UIGestureRecognizer *)sender {
	[self updateZoomParamsScalingToWidth:YES];
}

- (void)handleSingleTap:(UIGestureRecognizer *)sender {
	if (!self.comic && !toolbarHidden) {
		return;
	}
	
	CGPoint location = [sender locationInView:self.view];
	CGFloat quarterWidth = self.view.bounds.size.width * 0.25;
	
	if (location.x <= quarterWidth) {
		[self displayPage:(currentPageNumber - 1) animationDirection:1];
	}
	else if (location.x >= self.view.bounds.size.width - quarterWidth) {
		[self displayPage:(currentPageNumber + 1) animationDirection:-1];
	}
	else {
		[self toggleToolbars];
	}
}

- (void)toggleToolbars {
	toolbarHidden = !toolbarHidden;
	
	__weak typeof(self) weakSelf = self;
	__weak __typeof(bottomToolbar) weakToolbar = bottomToolbar;
	__weak __typeof(topLabel) weakLabel = topLabel;
	
	if (toolbarHidden) {
		[UIView
		 animateWithDuration:0.3
		 animations:^{
			 CGRect frame = weakToolbar.frame;
			 frame.origin.y = weakSelf.view.bounds.size.height;
			 weakToolbar.frame = frame;
			 weakToolbar.alpha = 0;
			 
			 frame = weakLabel.frame;
			 frame.origin.y = -frame.size.height;
			 weakLabel.frame = frame;
			 weakLabel.alpha = 0;
		 }];
	}
	else {
		[UIView
		 animateWithDuration:0.3
		 animations:^{
			 CGRect frame = weakToolbar.frame;
			 frame.origin.y = weakSelf.view.bounds.size.height - frame.size.height - weakSelf.view.safeAreaInsets.bottom;
			 weakToolbar.frame = frame;
			 weakToolbar.alpha = 1;
			 
			 frame = weakLabel.frame;
			 frame.origin.y = weakSelf.view.safeAreaInsets.top;
			 weakLabel.frame = frame;
			 weakLabel.alpha = 1;
		 }];
	}
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)sender {
	if (self.comic) {
		if (sender.state == UIGestureRecognizerStateRecognized) {
			if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
				[self displayPage:(currentPageNumber + 1) animationDirection:-1];
			}
			else if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
				[self displayPage:(currentPageNumber - 1) animationDirection:1];
			}
		}
	}
}

- (void)comicRemoved:(NSDictionary *)item {
	NSString *path = item[@"path"];
	
	if (EQUAL_STR([self.comic.file stringByResolvingSymlinksInPath], [path stringByResolvingSymlinksInPath]) || [self.comic somewhereInSubdir:path]) {
		self.comic = nil;
	}
}

- (void)sliderValueChanged:(float)value {
	currentPageNumber = totalPagesNumber * value;
	
	[currentPageView.viewForZoom removeFromSuperview];
	currentPageView.viewForZoom = nil;
	
	[self displayPage:currentPageNumber animationDirection:0];
}

- (void)pageChanged {
	[[WCSettingsStorage sharedInstance] saveCurrentPage:currentPageNumber forFile:self.comic.file];
}

- (void)redrawInterfaceWithSize:(CGSize)size {
	CGRect screenFrame;
	screenFrame.origin = CGPointZero;
	screenFrame.size = size;

	[UIView setAnimationsEnabled:NO];

	CGRect frame = bottomToolbar.frame;
	frame.size.width = screenFrame.size.width;

	if (toolbarHidden) {
		frame.origin.y = screenFrame.size.height;
		bottomToolbar.alpha = 0;
	}
	else {
		frame.origin.y = screenFrame.size.height - frame.size.height;
		bottomToolbar.alpha = 1;
	}

	bottomToolbar.frame = frame;
	
	frame = topLabel.frame;
	frame.size.width = screenFrame.size.width;
	
	if (toolbarHidden) {
		topLabel.alpha = 0;
		frame.origin.y = -frame.size.height;
	}
	else {
		topLabel.alpha = 1;
		frame.origin.y = 0;
	}
	
	topLabel.frame = frame;
	
	frame = libraryButton.frame;
	frame.origin.x = 20;
	frame.origin.y = 10;
	libraryButton.frame = frame;
	
	frame = wifiButton.frame;
	frame.origin.x = libraryButton.frame.origin.x + libraryButton.frame.size.width + 15;
	frame.origin.y = libraryButton.frame.origin.y;
	wifiButton.frame = frame;
	
	frame = infoButton.frame;
	frame.origin.x = bottomToolbar.frame.size.width - frame.size.width - 20;
	frame.origin.y = libraryButton.frame.origin.y;
	infoButton.frame = frame;
	
	screenFrame.origin = CGPointZero;
	pagesView.frame = screenFrame;
	
	currentPageView.frame = pagesView.bounds;
	
	[self updateZoomParamsScalingToWidth:!isPad && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)];
	
	bottomToolbar.pageNumber = currentPageNumber + 1;

	[UIView setAnimationsEnabled:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[self redrawInterfaceWithSize:size];
	[self updateZoomParamsScalingToWidth:!isPad && (size.width > size.height)];
}

- (void)updateZoomParamsScalingToWidth:(BOOL)scaleWidth {
	CGSize imageSize = currentPageView.pageRect.size;

	CGFloat nScaleWidth = currentPageView.frame.size.width / imageSize.width;
	CGFloat nScaleHeight = currentPageView.frame.size.height / imageSize.height;

	CGFloat minimumZoom = MIN(nScaleWidth, nScaleHeight);
	currentPageView.minimumZoomScale = minimumZoom;

	if (scaleWidth) {
		[currentPageView setZoomScale:nScaleWidth animated:NO];
	}
	else {
		[currentPageView setZoomScale:minimumZoom animated:NO];
	}

	[currentPageView scrollViewDidZoom:currentPageView];
	[currentPageView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)displayPage:(NSInteger)pageNum animationDirection:(NSInteger)animationDirection {
	if (!self.comic) {
		bottomToolbar.pageNumber = -1;
	}

	if (pageNum < 0 || pageNum >= totalPagesNumber) {
		return;
	}
	
	__block WCScrollView *oldPageView = nil;

	if (animationDirection != 0) {
		oldPageView = currentPageView;

		currentPageView = [[WCScrollView alloc] initWithFrame:pagesView.bounds];
		
		if (animationDirection == 1) {
			[pagesView insertSubview:currentPageView aboveSubview:oldPageView];
			CGRect frame = currentPageView.frame;
			frame.origin.x = -frame.size.width;
			currentPageView.frame = frame;
			currentPageView.alpha = 0;
		}
		else {
			[pagesView insertSubview:currentPageView belowSubview:oldPageView];
		}
	}

	pagesView.userInteractionEnabled = NO;

	UIImage *img = [self.comic imageAtIndex:pageNum];
	CGRect pageRect = CGRectMake(0, 0, img.size.width, img.size.height);

	CGFloat c = currentPageView.frame.size.height / pageRect.size.height;
	pageRect.size.width = floor(c * pageRect.size.width * 0.5);
	pageRect.size.height = floor(c * pageRect.size.height * 0.5);
	
	currentPageView.pageRect = pageRect;
	
	UIView *pageContentView = [[UIView alloc] initWithFrame:pageRect];
	pageContentView.backgroundColor = RGB(255, 255, 255);
	CATiledLayer *tiledLayer = [[CATiledLayer alloc] init];
	tiledLayer.bounds = pageRect;
	tiledLayer.delegate = nil;
	tiledLayer.tileSize = CGSizeMake(256, 256);
	tiledLayer.levelsOfDetail = 5;
	tiledLayer.levelsOfDetailBias = 5;
	tiledLayer.backgroundColor = RGB(255, 255, 255).CGColor;
	tiledLayer.frame = pageRect;
	[pageContentView.layer addSublayer:tiledLayer];
	[tiledLayer setContents:(id)[img CGImage]];
	[currentPageView addSubview:pageContentView];
	
	currentPageView.viewForZoom = pageContentView;
	
	currentPageNumber = pageNum;
	bottomToolbar.pageNumber = currentPageNumber + 1;

	[self pageChanged];
	[self updateZoomParamsScalingToWidth:!isPad && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)];

	pagesView.userInteractionEnabled = YES;
	
	bottomToolbar.pageNumber = currentPageNumber + 1;
	
	if (oldPageView) {
		__weak __typeof(currentPageView) weakCurrentPageView = currentPageView;
		
		[UIView
		 animateWithDuration:0.3
		 animations:^{
			 if (animationDirection == 1) {
				 CGRect frame = weakCurrentPageView.frame;
				 frame.origin.x = 0;
				 weakCurrentPageView.frame = frame;
				 weakCurrentPageView.alpha = 1;
			 }
			 else {
				 CGRect frame = oldPageView.frame;
				 frame.origin.x = (animationDirection == - 1) ? -frame.size.width : frame.size.width;
				 oldPageView.frame = frame;
				 oldPageView.alpha = 0;
			 }
		 }
		 completion:^(BOOL finished) {
			[oldPageView removeFromSuperview];
			oldPageView = nil;
		 }];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (self.comic) {
		animating = YES;

		if (!decelerate) {
			[self scrollViewDidEndDecelerating:scrollView];
		}
	}
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

@end
