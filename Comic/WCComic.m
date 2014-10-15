//
//  WCComic.m
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCComic.h"
#import "ZKDefs.h"
#import "ZKDataArchive.h"
#import "ZKCDHeader.h"
#import "URKArchive.h"
#import "URKArchiveAdditions.h"


@interface URKArchive(PublicAdditions)

- (BOOL)closeFile;

@end


@implementation WCComic {
	__strong __block ZKDataArchive *archive;
	__strong __block URKArchive *rarArchive;
	__block CGPDFDocumentRef pdfDoc;

	__block NSMutableArray *filesList;
	__block WCArchType archType;
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
			
			_numberOfPages = [filesList count];

			archType = WCZipFile;
		}
		
		if (archType != WCZipFile) {
			rarArchive = [URKArchive rarArchiveAtPath:aFile];
			BOOL ok = NO;
			NSArray *files = [rarArchive myUnrarListFiles];
			
			if ([files count]) {
				[filesList addObjectsFromArray:files];
				[filesList sortUsingSelector:@selector(caseInsensitiveCompare:)];
				archType = WCRarFile;
				ok = YES;
				
				_numberOfPages = [filesList count];
			}

			if (!ok) {
				[rarArchive closeFile];
				rarArchive = nil;
			}
		}
		
		if (archType == WCNone) {
			CFURLRef pdfURL = CFURLCreateWithFileSystemPath(NULL, (__bridge CFStringRef)aFile, kCFURLPOSIXPathStyle, FALSE);

			if (pdfURL != NULL) {
				pdfDoc = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);

				if (pdfDoc != NULL) {
					archType = WCPdfFile;

					_numberOfPages = CGPDFDocumentGetNumberOfPages(pdfDoc);
				}
				
				CFRelease(pdfURL);
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
	[rarArchive closeFile];
	rarArchive = nil;
	archType = WCNone;
	
	if (pdfDoc != NULL) {
		CGPDFDocumentRelease(pdfDoc);
		pdfDoc = NULL;
	}
}

- (UIImage *)imageAtIndex:(NSInteger)index {
	UIImage *img = nil;
	
	if (archType == WCZipFile) {
		ZKCDHeader *header = filesList[index];
		NSDictionary *attrs = nil;
		NSData *d = [archive inflateFile:header attributes:&attrs];
		img = [[UIImage alloc] initWithData:d];
	}
	else if (archType == WCRarFile) {
		NSData *data = [rarArchive extractDataFromFile:filesList[index] error:nil];

		if (data != nil) {
			img = [[UIImage alloc] initWithData:data];
		}
	}
	else if (archType == WCPdfFile) {
		CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfDoc, index + 1);
		
		if (pdfPage != NULL) {
			CGRect pageRect = CGRectIntegral(CGPDFPageGetBoxRect(pdfPage, kCGPDFCropBox));
			CGSize size = pageRect.size;
			CGSize screenSize = [UIScreen mainScreen].bounds.size;
			CGFloat maxSide = MAX(screenSize.width, screenSize.height);

			if (size.width < maxSide) {
				CGFloat c = maxSide / size.width;
				size.width = maxSide;
				size.height = floorf(size.height * c);
			}

			if (size.height < maxSide) {
				CGFloat c = maxSide / size.height;
				size.height = maxSide;
				size.width = floorf(size.width * c);
			}
			
			CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfDoc, index + 1);
			
			UIGraphicsBeginImageContextWithOptions(size, true, 0);
			
			CGContextRef ctx = UIGraphicsGetCurrentContext();
			
			CGContextGetCTM(ctx);
			CGContextScaleCTM(ctx, 1, -1);
			CGContextTranslateCTM(ctx, 0, -size.height);
			
			CGRect mediaRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFCropBox);
			CGContextScaleCTM(ctx, size.width / mediaRect.size.width, size.height / mediaRect.size.height);
			CGContextTranslateCTM(ctx, -mediaRect.origin.x, -mediaRect.origin.y);
			
			CGContextDrawPDFPage(ctx, pdfPage);
		
			img = UIGraphicsGetImageFromCurrentImageContext();

			UIGraphicsEndImageContext();
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

+ (void)createCoverImageForPath:(NSString *)path withCallback:(void(^)(UIImage *image, NSString *file))callback {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		ZKDataArchive *arch = [ZKDataArchive archiveWithArchivePath:path];

		if (arch && [arch.centralDirectory count]) {
			for (NSInteger i = 0; i < [arch.centralDirectory count]; i++) {
				ZKCDHeader *header = arch.centralDirectory[i];
				
				NSDictionary *attrs = nil;
				NSData *coverData = [arch inflateFile:header attributes:&attrs];
				
				UIImage *cover = [[UIImage alloc] initWithData:coverData];
				
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
					NSData *newCoverData = UIImageJPEGRepresentation(newImage, 0.8f);
					
					__block NSString *coverFile = [NSString stringWithFormat:@"%@/covers/%@_wcomics_cover_file", DOCPATH, [path lastPathComponent]];
					[newCoverData writeToFile:coverFile options:0 error:nil];
					
					if (callback) {
						dispatch_async(dispatch_get_main_queue(), ^{
							callback(newImage, coverFile);
						});
					}
					
					return;
				}
			}
		}
		else {
			URKArchive *rarArchive = [URKArchive rarArchiveAtPath:path];
			BOOL ok = NO;
			NSArray *files = [rarArchive myUnrarListFiles];
			
			if ([files count]) {
				for (NSString *file in files) {
					NSData *coverData = [rarArchive extractDataFromFile:file error:nil];
					
					UIImage *cover = [[UIImage alloc] initWithData:coverData];
					
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
						NSData *newCoverData = UIImageJPEGRepresentation(newImage, 0.8f);
						
						__block NSString *coverFile = [NSString stringWithFormat:@"%@/covers/%@_wcomics_cover_file", DOCPATH, [path lastPathComponent]];
						[newCoverData writeToFile:coverFile options:0 error:nil];
						
						if (callback) {
							dispatch_async(dispatch_get_main_queue(), ^{
								callback(newImage, coverFile);
							});
						}
						
						break;
					}
				}

				ok = YES;
			}
			
			[rarArchive closeFile];
			
			if (!ok) {
				CFURLRef pdfURL = CFURLCreateWithFileSystemPath(NULL, (__bridge CFStringRef)path, kCFURLPOSIXPathStyle, FALSE);
				
				if (pdfURL != NULL) {
					CGPDFDocumentRef pdfDoc = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
					CFRelease(pdfURL);

					if (pdfDoc != NULL) {
						CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfDoc, 1);
						
						if (pdfPage != NULL) {
							CGRect pageRect = CGRectIntegral(CGPDFPageGetBoxRect(pdfPage, kCGPDFCropBox));
							
							CGSize size = pageRect.size;
							
							CGFloat c = 31.0f / size.width;
							CGSize newSize = CGSizeMake(size.width * c, size.height * c);
							
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
							
							UIGraphicsBeginImageContextWithOptions(newSize, false, 0);
							
							CGContextRef context = UIGraphicsGetCurrentContext();
							
							CGRect bounds = CGContextGetClipBoundingBox(context);
							CGContextTranslateCTM(context, 0, bounds.size.height);
							CGContextScaleCTM(context, 1.0, -1.0);
							
							CGContextSaveGState(context);
							
							CGRect transformRect = CGRectMake(0, 0, newSize.width, newSize.height);
							CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(pdfPage, kCGPDFCropBox, transformRect, 0, true);
							
							CGContextConcatCTM(context, pdfTransform);
							
							CGContextDrawPDFPage(context, pdfPage);
							
							CGContextRestoreGState(context);
							
							UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
							
							NSData *newCoverData = UIImageJPEGRepresentation(newImage, 0.8f);
							__block NSString *coverFile = [NSString stringWithFormat:@"%@/covers/%@_wcomics_cover_file", DOCPATH, [path lastPathComponent]];
							[newCoverData writeToFile:coverFile options:0 error:nil];
							
							UIGraphicsEndImageContext();
							
							if (callback) {
								dispatch_async(dispatch_get_main_queue(), ^{
									callback(newImage, coverFile);
								});
							}
							
							return;
						}
						
						CGPDFDocumentRelease(pdfDoc);
					}
				}
			}
		}
	});
}

- (void)dealloc {
	filesList = nil;
	archive = nil;
	[rarArchive closeFile];
	rarArchive = nil;
	rarArchive = nil;
	self.file = nil;
	self.title = nil;
}

@end
