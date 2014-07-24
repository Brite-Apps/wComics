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

@implementation WCViewerViewController {
	UIView *pagesView;
	__block WCScrollView *currentPageView;
	
	NSInteger currentPageNumber;
	NSInteger totalPagesNumber;
	
	BOOL animating;
	
	UIPopoverController *currentPopover;
	UINavigationController *navController;
	
	BOOL scaleWidth;
	
	UILabel *topLabel;
	__block WCSliderToolbar *bottomToolbar;
	
	UIButton *libraryButton;
	UIButton *wifiButton;
	UIButton *infoButton;
	
	BOOL toolbarHidden;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.view.backgroundColor = RGB(0, 0, 0);
	
	toolbarHidden = YES;
	
	CGRect frame;
	frame.origin.x = 0.0f;
	frame.origin.y = self.view.bounds.size.height;
	frame.size.width = self.view.bounds.size.width;
	frame.size.height = 100.0f;
	
	bottomToolbar = [[WCSliderToolbar alloc] initWithFrame:CGRectIntegral(frame)];
	bottomToolbar.backgroundColor = RGBA(0, 0, 0, 0.8f);
	bottomToolbar.target = self;
	bottomToolbar.selector = @selector(progressChanged:);
	[self.view addSubview:bottomToolbar];
	
	frame.size.height = 44.0f;
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
	
	scaleWidth = NO;
	
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
	[self redrawInterface];
}

- (void)showErrorAlert {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING", @"Warning alert title")
													message:NSLocalizedString(@"CANNOT_OPEN_FILE", @"Cannot open file")
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
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

			if (_comic) {
				[[WCSettingsStorage sharedInstance] saveCurrentPage:currentPageNumber forFile:_comic.file];
			}

			currentPageNumber = [[WCSettingsStorage sharedInstance] currentPageForFile:aComic.file];
			totalPagesNumber = aComic.numberOfPages;

			bottomToolbar.pageNumber = currentPageNumber + 1;
			bottomToolbar.totalPages = totalPagesNumber;

			[_comic close];
			_comic = aComic;

			[[WCSettingsStorage sharedInstance] setLastDocument:_comic.file];

			topLabel.text = _comic.title;

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

	UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CLOSE", @"Close") style:UIBarButtonItemStyleDone target:self action:@selector(hideInfo)];
	v.navigationItem.rightBarButtonItem = closeItem;
	
	[self presentViewController:nav animated:YES completion:NULL];
}

- (void)hideInfo {
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)libraryItemSelected:(NSDictionary *)item {
	[currentPopover dismissPopoverAnimated:YES];
	currentPopover = nil;
	
	if (!EQUAL_STR([item[@"path"] stringByResolvingSymlinksInPath], [_comic.file stringByResolvingSymlinksInPath])) {
		WCComic *newComic = [[WCComic alloc] initWithFile:item[@"path"]];

		if (newComic) {
			self.comic = newComic;
		}
	}
}

- (void)showLibrary {
	if (!navController) {
		WCLibraryViewController *libraryViewController = [[WCLibraryViewController alloc] initWithStyle:UITableViewStylePlain];
		libraryViewController.dataSource = [WCLibraryDataSource sharedInstance].library;
		libraryViewController.title = NSLocalizedString(@"LIBRARY", @"Library");
		libraryViewController.preferredContentSize = CGSizeMake(500.0f, 650.0f);
		libraryViewController.target = self;
		libraryViewController.selector = @selector(libraryItemSelected:);

		navController = [[UINavigationController alloc] initWithRootViewController:libraryViewController];

		[[NSNotificationCenter defaultCenter] addObserver:navController selector:@selector(popToRootViewControllerAnimated:) name:LIBRARY_UPDATED_NOTIFICATION object:nil];
	}
	
	CGRect sourceRect = [self.view convertRect:libraryButton.frame fromView:bottomToolbar];

	currentPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
	currentPopover.delegate = self;
	[currentPopover presentPopoverFromRect:sourceRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void)dismissPopover {
	[currentPopover dismissPopoverAnimated:NO];
	currentPopover = nil;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	currentPopover = nil;
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
	scaleWidth = !scaleWidth;
	[self updateZoomParams];
}

- (void)handleSingleTap:(UIGestureRecognizer *)sender {
	if (!_comic && !toolbarHidden) {
		return;
	}
	
	CGPoint location = [sender locationInView:self.view];
	CGFloat quarterWidth = self.view.bounds.size.width * 0.25f;
	
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
	
	if (toolbarHidden) {
		[UIView
		 animateWithDuration:0.3
		 animations:^{
			 CGRect frame = bottomToolbar.frame;
			 frame.origin.y = weakSelf.view.bounds.size.height;
			 bottomToolbar.frame = frame;
			 bottomToolbar.alpha = 0.0f;
			 
			 frame = topLabel.frame;
			 frame.origin.y = -frame.size.height;
			 topLabel.frame = frame;
			 topLabel.alpha = 0.0f;
		 }];
	}
	else {
		[UIView
		 animateWithDuration:0.3
		 animations:^{
			 CGRect frame = bottomToolbar.frame;
			 frame.origin.y = weakSelf.view.bounds.size.height - frame.size.height;
			 bottomToolbar.frame = frame;
			 bottomToolbar.alpha = 1.0f;
			 
			 frame = topLabel.frame;
			 frame.origin.y = 0.0f;
			 topLabel.frame = frame;
			 topLabel.alpha = 1.0f;
		 }];
	}
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)sender {
	if (_comic) {
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
	
	if (EQUAL_STR([_comic.file stringByResolvingSymlinksInPath], [path stringByResolvingSymlinksInPath]) || [self.comic somewhereInSubdir:path]) {
		self.comic = nil;
	}
}

- (void)progressChanged:(NSNumber *)progress {
	currentPageNumber = totalPagesNumber * [progress floatValue];
	[self displayPage:currentPageNumber animationDirection:0];
}

- (void)pageChanged {
	[[WCSettingsStorage sharedInstance] saveCurrentPage:currentPageNumber forFile:_comic.file];
}

- (void)redrawInterface {
	CGRect screenFrame = self.view.bounds;

	[UIView setAnimationsEnabled:NO];

	CGRect tmpRect = bottomToolbar.frame;
	tmpRect.size.width = screenFrame.size.width;

	if (toolbarHidden) {
		tmpRect.origin.y = screenFrame.size.height;
		bottomToolbar.alpha = 0.0f;
	}
	else {
		tmpRect.origin.y = screenFrame.size.height - tmpRect.size.height;
		bottomToolbar.alpha = 1.0f;
	}

	bottomToolbar.frame = tmpRect;
	
	tmpRect = topLabel.frame;
	tmpRect.size.width = screenFrame.size.width;
	
	if (toolbarHidden) {
		topLabel.alpha = 0.0f;
		tmpRect.origin.y = -tmpRect.size.height;
	}
	else {
		topLabel.alpha = 1.0f;
		tmpRect.origin.y = 0.0f;
	}
	
	topLabel.frame = tmpRect;
	
	tmpRect = libraryButton.frame;
	tmpRect.origin.x = 20.0f;
	tmpRect.origin.y = 10.0f;
	libraryButton.frame = tmpRect;
	
	tmpRect = wifiButton.frame;
	tmpRect.origin.x = libraryButton.frame.origin.x + libraryButton.frame.size.width + 15.0f;
	tmpRect.origin.y = libraryButton.frame.origin.y;
	wifiButton.frame = tmpRect;
	
	tmpRect = infoButton.frame;
	tmpRect.origin.x = bottomToolbar.frame.size.width - tmpRect.size.width - 20.0f;
	tmpRect.origin.y = libraryButton.frame.origin.y;
	infoButton.frame = tmpRect;
	
	screenFrame.origin = CGPointZero;
	pagesView.frame = screenFrame;
	
	currentPageView.frame = pagesView.bounds;
	
	[self updateZoomParams];
	
	bottomToolbar.pageNumber = currentPageNumber + 1;

	[UIView setAnimationsEnabled:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[self redrawInterface];
}

- (BOOL)shouldAutorotate {
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self updateZoomParams];
}

- (void)updateZoomParams {
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
	[currentPageView scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:NO];
}

- (void)displayPage:(NSInteger)pageNum animationDirection:(NSInteger)animationDirection {
	if (!_comic) {
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
			currentPageView.alpha = 0.0f;
		}
		else {
			[pagesView insertSubview:currentPageView belowSubview:oldPageView];
		}
	}

	pagesView.userInteractionEnabled = NO;

	UIImage *img = [_comic imageAtIndex:pageNum];
	CGRect pageRect = CGRectMake(0.0f, 0.0f, img.size.width, img.size.height);

	CGFloat c = currentPageView.frame.size.height / pageRect.size.height;
	pageRect.size.width = floorf(c * pageRect.size.width * 0.5f);
	pageRect.size.height = floorf(c * pageRect.size.height * 0.5f);
	
	currentPageView.pageRect = pageRect;
	
	UIView *pageContentView = [[UIView alloc] initWithFrame:pageRect];
	pageContentView.backgroundColor = RGB(255, 255, 255);
	CATiledLayer *tiledLayer = [[CATiledLayer alloc] init];
	tiledLayer.bounds = pageRect;
	tiledLayer.delegate = nil;
	tiledLayer.tileSize = CGSizeMake(256.0f, 256.0f);
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
	[self updateZoomParams];
	
	pagesView.userInteractionEnabled = YES;
	
	bottomToolbar.pageNumber = currentPageNumber + 1;
	
	if (oldPageView) {
		[UIView
		 animateWithDuration:0.3
		 animations:^{
			 if (animationDirection == 1) {
				 CGRect frame = currentPageView.frame;
				 frame.origin.x = 0.0f;
				 currentPageView.frame = frame;
				 currentPageView.alpha = 1.0f;
			 }
			 else {
				 CGRect frame = oldPageView.frame;
				 frame.origin.x = (animationDirection == - 1) ? -frame.size.width : frame.size.width;
				 oldPageView.frame = frame;
				 oldPageView.alpha = 0.0f;
			 }
		 }
		 completion:^(BOOL finished) {
			 [oldPageView removeFromSuperview], oldPageView = nil;
		 }];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (_comic) {
		animating = YES;

		if (!decelerate) {
			[self scrollViewDidEndDecelerating:scrollView];
		}
	}
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:navController];
	self.comic = nil;
	navController = nil;
}

@end
