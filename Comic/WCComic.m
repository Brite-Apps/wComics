/**
 * @class WCComic
 * @author Nik Dyonin <wolf.step@gmail.com>
 */

#import "WCComic.h"
#import "ZKDefs.h"
#import "ZKDataArchive.h"
#import "ZKCDHeader.h"
#import "Unrar4iOS.h"
#import "Unrar4iOSAdditions.h"

@implementation WCComic

+ (void)createCoverImageForFile:(NSString *)path {
	@autoreleasepool {
		ZKDataArchive *arch = [ZKDataArchive archiveWithArchivePath:path];
		if (arch && [arch.centralDirectory count]) {
			UIImage *cover = nil;
			
			for (NSInteger i = 0; i < [arch.centralDirectory count]; i++) {
				ZKCDHeader *header = [arch.centralDirectory objectAtIndex:i];
				NSDictionary *attrs = nil;
				NSData *coverData = [arch inflateFile:header attributes:&attrs];

				cover = [[UIImage alloc] initWithData:coverData];

				if (cover.size.width == 0) {
					continue;
				}
				else {
					CGFloat c = 31.0f / cover.size.width;
					CGSize newSize = CGSizeMake(cover.size.width * c, cover.size.height * c);
					
					if (newSize.width > 31.0f) {
						c = 31.0f / newSize.width;
						newSize.width = 31.0f;
						newSize.height *= c;
					}
					
					if (newSize.height > 40.0f) {
						c = 40.0f / newSize.height;
						newSize.height = 40.0f;
						newSize.width *= c;
					}
					
					UIGraphicsBeginImageContextWithOptions(newSize, YES, [UIScreen mainScreen].scale);
					[cover drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
					UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
					UIGraphicsEndImageContext();
					NSData *newCoverData = UIImageJPEGRepresentation(newImage, 0.9f);
					
					NSString *coverFile = [NSString stringWithFormat:@"%@/covers/%@_wcomics_cover_file", DOCPATH, [path lastPathComponent]];
					[newCoverData writeToFile:coverFile options:0 error:nil];

					break;
				}
			}
		}
		else {
			Unrar4iOS *unrar = [[Unrar4iOS alloc] init];

			if ([unrar unrarOpenFile:path]) {
				NSArray *files = [unrar myUnrarListFiles];
				UIImage *cover = nil;

				for (NSInteger i = 0; i < [files count]; i++) {
					NSData *coverData = [unrar extractStream:[files objectAtIndex:i]];

					cover = [[UIImage alloc] initWithData:coverData];

					if (cover.size.width == 0) {
						continue;
					}
					else {
						CGFloat c = 31.0f / cover.size.width;
						CGSize newSize = CGSizeMake(cover.size.width * c, cover.size.height * c);
						
						if (newSize.width > 31.0f) {
							c = 31.0f / newSize.width;
							newSize.width = 31.0f;
							newSize.height *= c;
						}
						
						if (newSize.height > 40.0f) {
							c = 40.0f / newSize.height;
							newSize.height = 40.0f;
							newSize.width *= c;
						}
						
						TRACE(@"New size: %@", NSStringFromCGSize(newSize));
						
						UIGraphicsBeginImageContextWithOptions(newSize, YES, [UIScreen mainScreen].scale);
						[cover drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
						UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
						UIGraphicsEndImageContext();
						NSData *newCoverData = UIImageJPEGRepresentation(newImage, 0.9f);
						
						NSString *coverFile = [NSString stringWithFormat:@"%@/covers/%@_wcomics_cover_file", DOCPATH, [path lastPathComponent]];
					
						[newCoverData writeToFile:coverFile options:0 error:nil];

						break;
					}
				}
			}

			[unrar unrarCloseFile];
		}
	}
}

- (id)initWithFile:(NSString *)aFile {
	if (![[NSFileManager defaultManager] fileExistsAtPath:aFile]) {
		return nil;
	}

	if ((self = [super init]) != nil) {
		self.file = aFile;
		archType = WCNone;
		
		NSString *title = [[_file lastPathComponent] stringByDeletingPathExtension];
		self.title = title;

		filesList = [[NSMutableArray alloc] init];
		
		archive = [ZKDataArchive archiveWithArchivePath:_file];
		
		if (archive && [archive.centralDirectory count]) {
			NSArray *validExtensions = @[@"jpg", @"jpeg", @"png", @"gif", @"tiff", @"tif"];
			
			for (ZKCDHeader *header in archive.centralDirectory) {
				NSString *filename = header.filename;
				NSString *ext = [[filename pathExtension] lowercaseString];

				if ([validExtensions containsObject:ext]) {
					[filesList addObject:header];
				}
			}
			
			[filesList sortUsingComparator:^NSComparisonResult(ZKCDHeader *header1, ZKCDHeader *header2) {
				return [header1.filename caseInsensitiveCompare:header2.filename];
			}];

			archType = WCZipFile;
		}
		
		if (archType != WCZipFile) {
			rarArchive = [[Unrar4iOS alloc] init];
			BOOL ok = [rarArchive unrarOpenFile:aFile];

			if (ok) {
				[filesList addObjectsFromArray:[rarArchive myUnrarListFiles]];
				[filesList sortUsingSelector:@selector(caseInsensitiveCompare:)];
				archType = WCRarFile;
			}
			else {
				[rarArchive unrarCloseFile];
				rarArchive = nil;
			}
		}

		if (archType == WCNone) {
			return nil;
		}
	}
	return self;
}

- (void)close {
	archive = nil;
	[rarArchive unrarCloseFile];
	rarArchive = nil;
	archType = WCNone;
}

- (UIImage *)imageAtIndex:(NSInteger)index {
	UIImage *img = nil;
	
	if (archType == WCZipFile) {
		ZKCDHeader *header = [filesList objectAtIndex:index];
		NSDictionary *attrs = nil;
		NSData *d = [archive inflateFile:header attributes:&attrs];
		img = [[UIImage alloc] initWithData:d];
	}
	else if (archType == WCRarFile) {
		NSData *data = [rarArchive extractStream:[filesList objectAtIndex:index]];

		if (data != nil) {
			img = [[UIImage alloc] initWithData:data];
		}
	}
	return img;
}

- (BOOL)isEqual:(WCComic *)aComic {
	return EQUAL_STR([aComic.file stringByResolvingSymlinksInPath], [self.file stringByResolvingSymlinksInPath]);
}

- (BOOL)somewhereInSubdir:(NSString *)dir {
	BOOL result = NO;

	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];

	for (NSString *item in files) {
		BOOL isDir;
		NSString *fullPath = [dir stringByAppendingPathComponent:item];

		if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir]) {
			if (isDir) {
				result = [self somewhereInSubdir:fullPath];

				if (result) {
					return YES;
				}
			}
			else {
				if (EQUAL_STR([self.file stringByResolvingSymlinksInPath], [fullPath stringByResolvingSymlinksInPath])) {
					return YES;
				}
			}
		}
	}

	return result;
}

- (NSInteger)numberOfPages {
	return [filesList count];
}

- (void)dealloc {
	filesList = nil;
	archive = nil;
	[rarArchive unrarCloseFile];
	rarArchive = nil;
	rarArchive = nil;
	self.file = nil;
	self.title = nil;
}

@end
