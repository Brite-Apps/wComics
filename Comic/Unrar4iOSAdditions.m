#import "Unrar4iOSAdditions.h"

@implementation Unrar4iOS (wComicsAdditions)

- (NSArray *)myUnrarListFiles {
	int RHCode = 0, PFCode = 0;
	[self _unrarOpenFile:filename mode:RAR_OM_LIST];

	NSMutableArray *files = [NSMutableArray array];
	while ((RHCode = RARReadHeaderEx(_rarFile, header)) == 0) {
		NSString *_filename = [NSString stringWithCString:header->FileName encoding:NSASCIIStringEncoding];

		if (header->FileAttr != 16) {
			NSString *ext = [_filename pathExtension];
			NSComparisonResult jpg = [ext caseInsensitiveCompare:@"jpg"];
			NSComparisonResult jpeg = [ext caseInsensitiveCompare:@"jpeg"];
			NSComparisonResult png = [ext caseInsensitiveCompare:@"png"];
			NSComparisonResult gif = [ext caseInsensitiveCompare:@"gif"];
			NSComparisonResult tiff = [ext caseInsensitiveCompare:@"tiff"];
			NSComparisonResult tif = [ext caseInsensitiveCompare:@"tif"];
			
			if (
				jpg == NSOrderedSame ||
				jpeg == NSOrderedSame ||
				png == NSOrderedSame ||
				gif == NSOrderedSame ||
				tiff == NSOrderedSame ||
				tif == NSOrderedSame
				) {
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
