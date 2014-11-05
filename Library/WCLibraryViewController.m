//
//  WCLibraryViewController.m
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCLibraryViewController.h"
#import "WCViewerViewController.h"
#import "WCItemCell.h"
#import "WCComic.h"
#import "WCSettingsStorage.h"
#import "Common.h"

@implementation WCLibraryViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CLOSE", @"Close") style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewController)];
	self.navigationItem.rightBarButtonItem = closeItem;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (void)dismissModalViewController {
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellId = @"cellId";

	WCItemCell *cell = (WCItemCell *)[tableView dequeueReusableCellWithIdentifier:cellId];

	if (cell == nil) {
		cell = [[WCItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
	}

	NSDictionary *item = _dataSource[indexPath.row];
	cell.item = item;
	NSString *itemPath = item[@"path"];
	BOOL isDir = [item[@"dir"] boolValue];
	WCComic *currentComic = ((WCViewerViewController *)_target).comic;

	if (!isDir) {
		if (EQUAL_STR([currentComic.file stringByResolvingSymlinksInPath], [itemPath stringByResolvingSymlinksInPath])) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}

	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSDictionary *item = _dataSource[indexPath.row];

		[(WCViewerViewController *)_target comicRemoved:item];

		[[WCSettingsStorage sharedInstance] removeSettingsForFile:item[@"path"]];

		NSString *coverFile = [[NSString alloc] initWithFormat:@"%@/covers/%@_wcomics_cover_file", DOCPATH, [item[@"path"] lastPathComponent]];
		[[NSFileManager defaultManager] removeItemAtPath:coverFile error:nil];
		[[NSFileManager defaultManager] removeItemAtPath:item[@"path"] error:nil];
		[_dataSource removeObject:item];
		
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];

		if (![_dataSource count]) {
			[self.navigationController popViewControllerAnimated:YES];
		}
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *item = _dataSource[indexPath.row];

	if ([item[@"dir"] boolValue]) {
		WCLibraryViewController *lvc = [[WCLibraryViewController alloc] init];
		lvc.dataSource = item[@"children"];
		lvc.title = [item[@"path"] lastPathComponent];
		lvc.target = _target;
		lvc.preferredContentSize = self.view.bounds.size;
		self.preferredContentSize = self.view.bounds.size;
		[self.navigationController pushViewController:lvc animated:YES];
	}
	else {
		[_target comicItemSelected:item];
	}
}

@end
