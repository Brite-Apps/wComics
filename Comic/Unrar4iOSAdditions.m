#import "Unrar4iOSAdditions.h"

@implementation Unrar4iOS (wComicsAdditions)

- (NSArray *)myUnrarListFiles {
	NSInteger RHCode = 0, PFCode = 0;
	[self _unrarOpenFile:filename mode:RAR_OM_LIST];

	NSArray *validExtensions = @[@"jpg", @"jpeg", @"png", @"gif", @"tiff", @"tif"];
	
	NSMutableArray *files = [NSMutableArray array];

	while ((RHCode = RARReadHeaderEx(_rarFile, header)) == 0) {
		NSString *_filename = [NSString stringWithCString:header->FileName encoding:NSASCIIStringEncoding];

		if (header->FileAttr != 16) {
			NSString *ext = [_filename pathExtension];

			if ([validExtensions containsObject:ext]) {
				[files addObject:_filename];
			}
		}

		if ((PFCode = RARProcessFile(_rarFile, RAR_SKIP, NULL, NULL)) != 0) {
			[self _unrarCloseFile];
			return nil;
		}
	}
	
	[self _unrarCloseFile];
	return files;
}

@end
