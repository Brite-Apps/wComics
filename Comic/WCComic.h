//
//  WCComic.h
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

@import Foundation;
@import UIKit;

@class URKArchive;
@class ZKDataArchive;

typedef NS_ENUM(NSInteger, WCArchType) {
	WCZipFile = 1,
	WCRarFile = 2,
	WCPdfFile = 3,
	WCNone = 4
};

@interface WCComic : NSObject

@property (nonatomic, strong) NSString *file;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, readonly) NSInteger numberOfPages;

- (id)initWithFile:(NSString *)aFile;
- (UIImage *)imageAtIndex:(NSInteger)index;
- (void)close;
- (BOOL)somewhereInSubdir:(NSString *)dir;
+ (void)createCoverImageForPath:(NSString *)path withCallback:(void(^)(UIImage *image, NSString *file))callback;

@end
