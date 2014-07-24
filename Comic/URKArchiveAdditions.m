//
//  URKArchiveAdditions.m
//  wComics
//
//  Created by Nik Dyonin on 20.02.14.
//  Copyright (c) 2014 Nik Dyonin. All rights reserved.
//

#import "URKArchiveAdditions.h"

@implementation URKArchive (wComicsAdditions)

- (NSArray *)myUnrarListFiles {
	NSArray *validExtensions = @[@"jpg", @"jpeg", @"png", @"gif", @"tiff", @"tif"];
	NSArray *f = [self listFiles:nil];
	NSMutableArray *files = [NSMutableArray array];
	
	for (NSString *file in f) {
		NSString *ext = [file pathExtension];

		if ([validExtensions containsObject:ext]) {
			[files addObject:file];
		}
	}

	return files;
}

@end
