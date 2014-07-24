//
//  WCLibraryDataSource.m
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCLibraryDataSource.h"
#import "ZKDataArchive.h"
#import "WCComic.h"

NSComparisonResult compareItems(NSDictionary *item1, NSDictionary *item2, void *context) {
	NSString *name1 = [item1[@"path"] lastPathComponent];
	NSString *name2 = [item2[@"path"] lastPathComponent];
	return [name1 caseInsensitiveCompare:name2];
}

@implementation WCLibraryDataSource {
	NSOperationQueue *coverRenderQueue;
}

+ (instancetype)sharedInstance {
	static dispatch_once_t pred;
	static WCLibraryDataSource *shared = nil;
	dispatch_once(&pred, ^{
		shared = [[self alloc] init];
	});
	return shared;
}

- (id)init {
	if ((self = [super init]) != nil) {
		_library = [[NSMutableArray alloc] init];
		coverRenderQueue = [[NSOperationQueue alloc] init];
		[self updateLibrary];
	}
	return self;
}

- (void)processItem:(NSString *)itemPath isDirectory:(BOOL)isDirectory parent:(NSMutableDictionary *)parent {
	NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
	item[@"path"] = itemPath;

	if (isDirectory) {
		item[@"dir"] = @YES;

		if (parent) {
			if (!parent[@"children"]) {
				NSMutableArray *children = [[NSMutableArray alloc] init];
				parent[@"children"] = children;
			}

			[parent[@"children"] addObject:item];
		}
		else {
			[_library addObject:item];
		}

		NSArray *itemsList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:itemPath error:nil];

		if ([itemsList count]) {
			for (NSString *itemName in itemsList) {
				NSString *p = [itemPath stringByAppendingPathComponent:itemName];
				BOOL isDir;

				if ([[NSFileManager defaultManager] fileExistsAtPath:p isDirectory:&isDir]) {
					[self processItem:p isDirectory:isDir parent:item];
				}
			}
		}
	}
	else {
		if (parent) {
			if (!parent[@"children"]) {
				NSMutableArray *children = [[NSMutableArray alloc] init];
				parent[@"children"] = children;
			}
			[parent[@"children"] addObject:item];
		}
		else {
			[_library addObject:item];
		}
	}
}

- (void)sortDirs:(NSMutableArray *)items {
	NSMutableArray *dirs = [[NSMutableArray alloc] init];
	NSMutableArray *comics = [[NSMutableArray alloc] init];

	for (NSDictionary *dict in items) {
		if ([dict[@"dir"] boolValue]) {
			[self sortDirs:dict[@"children"]];
			[dirs addObject:dict];
		}
		else {
			[comics addObject:dict];
		}
	}

	[items removeAllObjects];
	[dirs sortUsingFunction:compareItems context:nil];
	[comics sortUsingFunction:compareItems context:nil];

	[items addObjectsFromArray:dirs];
	[items addObjectsFromArray:comics];
}

- (void)updateLibrary {
	[coverRenderQueue cancelAllOperations];

	[_library removeAllObjects];
	
	[coverRenderQueue setSuspended:YES];
	
	NSArray *itemsList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:DOCPATH error:nil];

	for (NSString *itemName in itemsList) {
		if (EQUAL_STR(itemName, @"covers")) {
			continue;
		}
		
		if ([itemName hasPrefix:@"."]) {
			continue;
		}

		NSString *itemPath = [DOCPATH stringByAppendingPathComponent:itemName];
		
		BOOL isDirectory;

		if ([[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDirectory]) {
			[self processItem:itemPath isDirectory:isDirectory parent:nil];
		}
	}
	
	[self sortDirs:_library];

	[[NSNotificationCenter defaultCenter] postNotificationName:LIBRARY_UPDATED_NOTIFICATION object:nil];
	
	[coverRenderQueue setSuspended:NO];
}

- (void)dealloc {
	_library = nil;
}

@end
