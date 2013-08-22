/**
 * @class WCLibraryDataSource
 * @author Nik S Dyonin <wolf.step@gmail.com>
 */

static NSString *libraryMutex = @"libraryMutex";

#import "WCLibraryDataSource.h"
#import "ZKDataArchive.h"
#import <MobileCoreServices/MobileCoreServices.h>

NSComparisonResult compareItems(NSDictionary *item1, NSDictionary *item2, void *context) {
	NSString *name1 = [[item1 objectForKey:@"path"] lastPathComponent];
	NSString *name2 = [[item2 objectForKey:@"path"] lastPathComponent];
	return [name1 caseInsensitiveCompare:name2];
}

@implementation WCLibraryDataSource

+ (WCLibraryDataSource *)sharedInstance {
	static WCLibraryDataSource *shared;
	@synchronized (libraryMutex) {
		if (shared == nil) {
			@synchronized (libraryMutex) {
				shared = [[WCLibraryDataSource alloc] init];
			}
		}
	}
	return shared;
}

- (id)init {
	if ((self = [super init]) != nil) {
		_library = [[NSMutableArray alloc] init];
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
		NSString *coverFile = [NSString stringWithFormat:@"%@/covers/%@_wcomics_cover_file", DOCPATH, [itemPath lastPathComponent]];
		if (![[NSFileManager defaultManager] fileExistsAtPath:coverFile]) {
			[WCComic createCoverImageForFile:itemPath];
		}
		if (parent) {
			if (![parent objectForKey:@"children"]) {
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
	@autoreleasepool {
		[_library removeAllObjects];
		
		NSArray *itemsList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:DOCPATH error:nil];
		for (NSString *itemName in itemsList) {
			if (EQUAL_STR(itemName, @"covers")) {
				continue;
			}
			NSString *itemPath = [DOCPATH stringByAppendingPathComponent:itemName];
			BOOL isDirectory;
			if ([[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDirectory]) {
				[self processItem:itemPath isDirectory:isDirectory parent:nil];
			}
		}
		
		[self sortDirs:_library];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:LIBRARY_UPDATED_NOTIFICATION object:nil];
}

- (void)dealloc {
	_library = nil;
}

@end
