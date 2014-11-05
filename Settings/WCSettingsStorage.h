//
//  WCSettingsStorage.h
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

@import Foundation;

@interface WCSettingsStorage : NSObject

@property (nonatomic, assign) NSString *lastDocument;

+ (instancetype)sharedInstance;
- (NSUInteger)currentPageForFile:(NSString *)file;
- (void)saveCurrentPage:(NSInteger)page forFile:(NSString *)file;
- (void)removeSettingsForFile:(NSString *)file;

@end
