//
//  WCComic.m
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCComic.h"
#import "MiniZip.h"
#import "UnRAR.h"
#import "Common.h"

extern NSOperationQueue *coversQueue;

@implementation WCComic {
	__block MiniZip *zipArchive;
	__block UnRAR *rarArchive;
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

		zipArchive = [[MiniZip alloc] initWithArchiveAtPath:aFile];
		
		if (zipArchive) {
			zipArchive.skipInvisibleFiles = YES;
			
			NSArray *validExtensions = @[@"jpg", @"jpeg", @"png", @"gif", @"tiff", @"tif"];
			
			for (NSString* file in [[zipArchive retrieveFileList] sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
				NSString *ext = [[file pathExtension] lowercaseString];
				
				if ([validExtensions containsObject:ext]) {
					[filesList addObject:file];
				}
			}

			_numberOfPages = [filesList count];

			archType = WCZipFile;
		}
		
		if (archType != WCZipFile) {
			rarArchive = [[UnRAR alloc] initWithArchiveAtPath:aFile];
			
			if (rarArchive) {
				rarArchive.skipInvisibleFiles = YES;
				
				NSArray *validExtensions = @[@"jpg", @"jpeg", @"png", @"gif", @"tiff", @"tif"];
				
				for (NSString* file in [[rarArchive retrieveFileList] sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
					NSString *ext = [[file pathExtension] lowercaseString];
					
					if ([validExtensions containsObject:ext]) {
						[filesList addObject:file];
					}
				}
				
				_numberOfPages = [filesList count];
				
				archType = WCRarFile;
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
	zipArchive = nil;
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
		NSString *temp = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
		
		if ([zipArchive extractFile:filesList[index] toPath:temp]) {
			NSData *d = [[NSData alloc] initWithContentsOfFile:temp];
			img = [[UIImage alloc] initWithData:d];
		}
		
		[[NSFileManager defaultManager] removeItemAtPath:temp error:nil];
	}
	else if (archType == WCRarFile) {
		NSString *temp = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
		
		if ([rarArchive extractFile:filesList[index] toPath:temp]) {
			NSData *d = [[NSData alloc] initWithContentsOfFile:temp];
			img = [[UIImage alloc] initWithData:d];
		}
		
		[[NSFileManager defaultManager] removeItemAtPath:temp error:nil];
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
	[coversQueue addOperationWithBlock:^{
		id archive = [[MiniZip alloc] initWithArchiveAtPath:path];
		
		if (archive == nil) {
			archive = [[UnRAR alloc] initWithArchiveAtPath:path];
		}
		
		if (archive) {
			[archive setSkipInvisibleFiles:YES];
			
			NSArray *validExtensions = @[@"jpg", @"jpeg", @"png", @"gif", @"tiff", @"tif"];
			
			for (NSString *file in [[archive retrieveFileList] sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
				NSString *ext = [[file pathExtension] lowercaseString];
				
				if ([validExtensions containsObject:ext]) {
					NSString *temp = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
					
					if ([archive extractFile:file toPath:temp]) {
						NSData *d = [[NSData alloc] initWithContentsOfFile:temp];
						UIImage *cover = [[UIImage alloc] initWithData:d];
						
						if (cover) {
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
					}
				}
			}
		}
		else {
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
					}
					
					CGPDFDocumentRelease(pdfDoc);
				}
			}
		}
	}];
}

- (void)dealloc {
	filesList = nil;
	zipArchive = nil;
	rarArchive = nil;
	self.file = nil;
	self.title = nil;

	if (pdfDoc != NULL) {
		CGPDFDocumentRelease(pdfDoc);
		pdfDoc = NULL;
	}
}

@end
