/**
 * @class WCViewerViewController
 * @author Nik S Dyonin <wolf.step@gmail.com>
 */

#import "WCViewerViewController.h"
#import "WCScrollView.h"
#import "WCLibraryViewController.h"
#import "WCServerViewController.h"
#import "WCInfoViewController.h"
#import "WCAppDelegate.h"

@implementation WCViewerViewController

- (void)showErrorAlert {
	UIAlertView *alert = [[UIAlertView alloc] init];
	alert.title = NSLocalizedString(@"WARNING", @"Warning alert title");
	alert.message = NSLocalizedString(@"CANNOT_OPEN_FILE", @"Cannot open file");
	[alert addButtonWithTitle:@"OK"];
	alert.cancelButtonIndex = 0;
	[alert show];
}

- (void)setComic:(WCComic *)aComic {
	if (aComic == nil) {
		[[pagesScrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
		[_comic close];
		_comic = nil;
		[[WCSettingsStorage sharedInstance] setLastDocument:nil];
		pagesScrollView.contentSize = CGSizeZero;
		self.title = @"wComics";
		bottomToolbar.pageNumber = -1;
	}
	else {
		if (![_comic isEqual:aComic]) {
			BOOL isDir;
			if (![[NSFileManager defaultManager] fileExistsAtPath:aComic.file isDirectory:&isDir]) {
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
			
			for (UIView *v in [pagesScrollView subviews]) {
				[v removeFromSuperview];
			}

			[_comic close];
			_comic = aComic;

			[self redrawInterface];

			[[WCSettingsStorage sharedInstance] setLastDocument:_comic.file];
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
	
	if (!EQUAL_STR([[item objectForKey:@"path"] stringByResolvingSymlinksInPath], [_comic.file stringByResolvingSymlinksInPath])) {
		WCComic *newComic = [[WCComic alloc] initWithFile:[item objectForKey:@"path"]];
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

	id appDelegate = [UIApplication sharedApplication].delegate;
	[appDelegate performSelector:@selector(showIndicator)];
	[appDelegate performSelectorInBackground:@selector(updateLibrary) withObject:nil];
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

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self redrawInterface];
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

	pagesScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
	[self.view insertSubview:pagesScrollView belowSubview:bottomToolbar];

	pagesScrollView.pagingEnabled = YES;
	pagesScrollView.bounces = NO;
	pagesScrollView.showsVerticalScrollIndicator = NO;
	pagesScrollView.showsHorizontalScrollIndicator = NO;
	pagesScrollView.delegate = self;
	
	self.title = @"wComics";
	
	scaleWidth = NO;
	
	UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapRecognizer.numberOfTapsRequired = 2;
	[pagesScrollView addGestureRecognizer:doubleTapRecognizer];

	UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	singleTapRecognizer.numberOfTapsRequired = 1;
	[singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
	[pagesScrollView addGestureRecognizer:singleTapRecognizer];
}

- (void)handleDoubleTap:(UIGestureRecognizer *)sender {
	scaleWidth = !scaleWidth;

	for (int i = currentPageNumber - 3; i <= currentPageNumber + 3; i++) {
		if (i >= 0 && i < totalPagesNumber) {
			[self updateZoomParams:i];
		}
	}
}

- (void)handleSingleTap:(UIGestureRecognizer *)sender {
	toolbarHidden = !toolbarHidden;
	
	if (toolbarHidden) {
		[UIView animateWithDuration:0.3
						 animations:^{
							 CGRect tmpRect = bottomToolbar.frame;
							 tmpRect.origin.y = self.view.bounds.size.height;
							 bottomToolbar.frame = tmpRect;
						 }
		 ];
	}
	else {
		[UIView animateWithDuration:0.3
						 animations:^{
							 CGRect tmpRect = bottomToolbar.frame;
							 tmpRect.origin.y = self.view.bounds.size.height - tmpRect.size.height;
							 bottomToolbar.frame = tmpRect;
						 }
		 ];
	}
}

- (void)comicRemoved:(NSDictionary *)item {
	NSString *path = [item objectForKey:@"path"];
	
	if (EQUAL_STR([_comic.file stringByResolvingSymlinksInPath], [path stringByResolvingSymlinksInPath]) || [self.comic somewhereInSubdir:path]) {
		self.comic = nil;
	}
}

- (void)progressChanged:(NSNumber *)progress {
	currentPageNumber = totalPagesNumber * [progress floatValue];
	CGPoint currentOffset = CGPointZero;
	currentOffset.x = currentPageNumber * pagesScrollView.frame.size.width;
	[pagesScrollView setContentOffset:currentOffset animated:NO];
	[self displayPage:currentPageNumber];
}

- (void)pageChanged {
	[[WCSettingsStorage sharedInstance] saveCurrentPage:currentPageNumber forFile:_comic.file];
	for (WCScrollView *v in [pagesScrollView subviews]) {
		if ([v isKindOfClass:[WCScrollView class]]) {
			if (v.tag < currentPageNumber || v.tag > currentPageNumber + 2) {
				[v removeFromSuperview];
			}
		}
	}
}

- (void)redrawInterface {
	@synchronized (self) {
		CGRect screenFrame = self.view.bounds;

		[UIView setAnimationsEnabled:NO];

		CGRect tmpRect = bottomToolbar.frame;
		tmpRect.size.width = screenFrame.size.width;
		if (toolbarHidden) {
			tmpRect.origin.y = screenFrame.size.height;
		}
		else {
			tmpRect.origin.y = screenFrame.size.height - tmpRect.size.height;
		}
		bottomToolbar.frame = tmpRect;
		
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
		pagesScrollView.frame = screenFrame;

		float totalWidth = screenFrame.size.width * totalPagesNumber;
		pagesScrollView.contentSize = CGSizeMake(totalWidth, screenFrame.size.height);
		
		tmpRect = _updateIndicator.frame;
		tmpRect.origin.x = floorf((screenFrame.size.width - tmpRect.size.width) / 2.0f);
		tmpRect.origin.y = floorf((screenFrame.size.height - tmpRect.size.height) / 2.0f);
		_updateIndicator.frame = tmpRect;
		
		for (UIImageView *v in [pagesScrollView subviews]) {
			if ([v isKindOfClass:[UIImageView class]]) {
				[v removeFromSuperview];
			}
		}

		for (int i = 0; i < totalPagesNumber; i++) {
			WCScrollView *wcScrollView = (WCScrollView *)[pagesScrollView viewWithTag:i + 1];
			if (wcScrollView) {
				wcScrollView.frame = pagesScrollView.frame;
				CGRect tmpRect = wcScrollView.frame;
				float offset = i * pagesScrollView.frame.size.width;
				tmpRect.origin.x = offset;
				wcScrollView.frame = tmpRect;
			}
			
			UIImageView *img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"info"]];
			CGRect tmpRect = img.frame;
			tmpRect.origin.x = floorf((pagesScrollView.frame.size.width - tmpRect.size.width) / 2.0f) + pagesScrollView.frame.size.width * i;
			tmpRect.origin.y = floorf((pagesScrollView.frame.size.height - tmpRect.size.height) / 2.0f);
			img.frame = tmpRect;
			[pagesScrollView insertSubview:img atIndex:0];
		}

		CGPoint currentOffset = CGPointZero;
		currentOffset.x = currentPageNumber * pagesScrollView.frame.size.width;
		[pagesScrollView setContentOffset:currentOffset animated:NO];
		[self displayPage:currentPageNumber];

		[UIView setAnimationsEnabled:YES];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	for (WCScrollView *v in [pagesScrollView subviews]) {
		if ([v isKindOfClass:[WCScrollView class]]) {
			[v removeFromSuperview];
		}
	}
	[self redrawInterface];
}

- (BOOL)shouldAutorotate {
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self updateZoomParams:currentPageNumber];
}

- (void)updateZoomParams:(int)pageNum {
	WCScrollView *scrollView = (WCScrollView *)[pagesScrollView viewWithTag:pageNum + 1];
	CGSize imageSize = scrollView.pageRect.size;

	float nScaleWidth = scrollView.frame.size.width / imageSize.width;
	float nScaleHeight = scrollView.frame.size.height / imageSize.height;

	float minimumZoom = MIN(nScaleWidth, nScaleHeight);
	scrollView.minimumZoomScale = minimumZoom;

	if (scaleWidth) {
		[scrollView setZoomScale:nScaleWidth animated:NO];
	}
	else {
		[scrollView setZoomScale:minimumZoom animated:NO];
	}

	[scrollView scrollViewDidZoom:scrollView];
	[scrollView scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:NO];
}

- (void)displayPage:(int)pageNum {
	if (_comic) {
		self.title = _comic.title;
	}
	else {
		self.title = @"wComics";
		bottomToolbar.pageNumber = -1;
	}

	if (pageNum < 0 || pageNum >= totalPagesNumber) {
		return;
	}

	@autoreleasepool {
		@synchronized (self) {
			pagesScrollView.userInteractionEnabled = NO;
			WCScrollView *scrollView = (WCScrollView *)[pagesScrollView viewWithTag:pageNum + 1];
			
			if (!scrollView) {
				scrollView = [[WCScrollView alloc] initWithFrame:pagesScrollView.frame];
				UIImage *img = [_comic imageAtIndex:pageNum];
				CGRect pageRect = CGRectMake(0.0f, 0.0f, img.size.width, img.size.height);
				
				float c = scrollView.frame.size.height / pageRect.size.height;
				pageRect.size.width = floorf(c * pageRect.size.width * 0.5f);
				pageRect.size.height = floorf(c * pageRect.size.height * 0.5f);
				
				scrollView.pageRect = pageRect;
				
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
				[scrollView addSubview:pageContentView];
				
				scrollView.viewForZoom = pageContentView;
				
				CGRect tmpRect = scrollView.frame;
				float offset = pageNum * pagesScrollView.frame.size.width;
				tmpRect.origin.x = offset;
				scrollView.frame = tmpRect;
				[pagesScrollView addSubview:scrollView];
				scrollView.tag = pageNum + 1;
				[self pageChanged];
			}
			[self updateZoomParams:pageNum];
			
			if (pageNum == currentPageNumber) {
				[self displayPage:(pageNum - 1)];
				[self displayPage:(pageNum + 1)];
			}
			pagesScrollView.userInteractionEnabled = YES;
		}
		
		bottomToolbar.pageNumber = currentPageNumber + 1;
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

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if (_comic) {
		animating = YES;
		if (scrollView == pagesScrollView) {
			int newPageNumber = floorf(scrollView.contentOffset.x / scrollView.frame.size.width);
			if (newPageNumber != currentPageNumber) {
				currentPageNumber = newPageNumber;
				bottomToolbar.pageNumber = currentPageNumber + 1;
				[self displayPage:currentPageNumber];
			}
		}
		animating = NO;
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	if (!animating) {
		[self scrollViewDidEndDecelerating:scrollView];
	}
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:navController];
	self.comic = nil;
	navController = nil;
	self.updateIndicator = nil;
}

- (void)didReceiveMemoryWarning {
	for (int i = 1; i <= totalPagesNumber; i++) {
		if (i != currentPageNumber + 1) {
			WCScrollView *s = (WCScrollView *)[pagesScrollView viewWithTag:i];
			if (s && [s isKindOfClass:[WCScrollView class]]) {
				[s removeFromSuperview];
			}
		}
	}
	[self displayPage:currentPageNumber];
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

@end
