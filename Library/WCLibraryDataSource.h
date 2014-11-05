//
//  WCLibraryDataSource.h
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

@import Foundation;

@interface WCLibraryDataSource : NSObject

@property (nonatomic, readonly) NSMutableArray *library;

+ (instancetype)sharedInstance;
- (void)updateLibrary;

@end
