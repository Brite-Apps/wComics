/**
 * @class WCComic
 * @author Nik S Dyonin <nik@brite-apps.com>
 */

#import "WCComic.h"
#import "ZKDefs.h"
#import "ZKDataArchive.h"
#import "ZKCDHeader.h"

#import "Unrar4iOS.h"
#import "Unrar4iOSAdditions.h"

UIImage* cropImage(UIImage *imageToCrop, CGRect cropRect) {
	UIGraphicsBeginImageContext(cropRect.size);
	CGContextRef currentContext = UIGraphicsGetCurrentContext();

	CGRect clippedRect = CGRectMake(0, 0, cropRect.size.width, cropRect.size.height);
	CGContextClipToRect(currentContext, clippedRect);

	CGRect drawRect = CGRectMake(cropRect.origin.x * -1,
								 cropRect.origin.y * -1,
								 imageToCrop.size.width,
								 imageToCrop.size.height);
	
	CGContextTranslateCTM(currentContext, 0, drawRect.size.height);
	CGContextScaleCTM(currentContext, 1.0, -1.0);
	CGContextDrawImage(currentContext, drawRect, imageToCrop.CGImage);

	UIImage *cropped = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return cropped;
}

@implementation WCComic

+ (void)createCoverImageForFile:(NSString *)path {
	@autoreleasepool {
		ZKDataArchive *arch = [ZKDataArchive archiveWithArchivePath:path];
		if (arch && [arch.centralDirectory count]) {
			UIImage *cover = nil;
			
			for (int i = 0; i < [arch.centralDirectory count]; i++) {
				ZKCDHeader *header = [arch.centralDirectory objectAtIndex:i];
				NSDictionary *attrs = nil;
				NSData *coverData = [arch inflateFile:header attributes:&attrs];
				@try {
					cover = [[UIImage alloc] initWithData:coverData];
					if (cover.size.width == 0) {
						continue;
					}
					else {
						float c = 31.0f / cover.size.width;
						CGSize newSize = CGSizeMake(cover.size.width * c, cover.size.height * c);
						UIGraphicsBeginImageContext(newSize);
						[cover drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
						UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
						UIGraphicsEndImageContext();
						
						if (newSize.height > 40.0f) {
							newImage = cropImage(newImage, CGRectMake(0.0f, 0.0f, 31.0f, 40.0f));
						}
						
						NSData *newCoverData = UIImageJPEGRepresentation(newImage, 0.9f);
						
						NSString *coverFile = [NSString stringWithFormat:@"%@/covers/%@_wcomics_cover_file", DOCPATH, [path lastPathComponent]];
						[newCoverData writeToFile:coverFile options:0 error:nil];
					}
					break;
				}
				@catch (NSException *e) {
				}
			}
		}
		else {
			Unrar4iOS *unrar = [[Unrar4iOS alloc] init];
			BOOL ok = [unrar unrarOpenFile:path];
			if (ok) {
				NSArray *files = [unrar myUnrarListFiles];
				UIImage *cover = nil;
				for (int i = 0; i < [files count]; i++) {
					NSData *coverData = [unrar extractStream:[files objectAtIndex:i]];
					@try {
						cover = [[UIImage alloc] initWithData:coverData];
						if (cover.size.width == 0) {
							continue;
						}
						else {
							float c = 31.0f / cover.size.width;
							CGSize newSize = CGSizeMake(cover.size.width * c, cover.size.height * c);
							UIGraphicsBeginImageContext(newSize);
							[cover drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
							UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
							UIGraphicsEndImageContext();
							
							if (newSize.height > 40.0f) {
								newImage = cropImage(newImage, CGRectMake(0.0f, 0.0f, 31.0f, 40.0f));
							}
							
							NSData *newCoverData = UIImageJPEGRepresentation(newImage, 0.9f);
							
							NSString *coverFile = [NSString stringWithFormat:@"%@/covers/%@_wcomics_cover_file", DOCPATH, [path lastPathComponent]];
							[newCoverData writeToFile:coverFile options:0 error:nil];
						}
						break;
					}
					@catch (NSException *e) {
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

		@autoreleasepool {
			NSMutableString *titleStr = [[NSMutableString alloc] initWithString:[[_file componentsSeparatedByString:@"/"] lastObject]];
			[titleStr replaceOccurrencesOfString:@".cbz" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [titleStr length])];
			[titleStr replaceOccurrencesOfString:@".cbr" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [titleStr length])];
			self.title = [[NSString alloc] initWithString:titleStr];
			
			filesList = [[NSMutableArray alloc] init];
			
			archive = [ZKDataArchive archiveWithArchivePath:_file];
			
			if (archive && [archive.centralDirectory count]) {
				for (ZKCDHeader *header in archive.centralDirectory) {
					NSString *filename = header.filename;
					NSString *ext = [filename pathExtension];

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
						[filesList addObject:header];
					}
				}
				archType = WCZipFile;
			}
			
			if (archType != WCZipFile) {
				rarArchive = [[Unrar4iOS alloc] init];
				BOOL ok = [rarArchive unrarOpenFile:aFile];
				if (ok) {
					[filesList addObjectsFromArray:[rarArchive myUnrarListFiles]];
					archType = WCRarFile;
				}
				else {
					[rarArchive unrarCloseFile];
					rarArchive = nil;
				}
			}
		}

		if (archType == WCNone) {
			return nil;
		}

		[filesList sortUsingSelector:@selector(compare:)];
	}
	return self;
}

- (void)close {
	archive = nil;
	[rarArchive unrarCloseFile];
	rarArchive = nil;
	archType = WCNone;
}

- (UIImage *)imageAtIndex:(int)index {
	@autoreleasepool {
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
}

- (BOOL)isEqual:(WCComic *)aComic {
	return EQUAL_STR([aComic.file stringByResolvingSymlinksInPath], [self.file stringByResolvingSymlinksInPath]);
}

- (BOOL)somewhereInSubdir:(NSString *)dir {
	BOOL result = NO;
	@autoreleasepool {
		NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];
		for (NSString *item in files) {
			BOOL isDir;
			NSString *fullPath = [dir stringByAppendingPathComponent:item];
			if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir]) {
				if (isDir) {
					result = [self somewhereInSubdir:dir];
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
	}

	return result;
}

- (int)numberOfPages {
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
