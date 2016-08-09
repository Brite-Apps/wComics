//
//  Common.h
//  wComics
//
//  Created by Nik Dyonin on 05.11.14.
//  Copyright (c) 2014 Nik S Dyonin. All rights reserved.
//

#ifndef wComics_Common_h
#define wComics_Common_h

#define DOCPATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define EQUAL_STR(a, b) [a isEqualToString:b]
#define RGB(a, b, c) [UIColor colorWithRed:(a / 255.0) green:(b / 255.0) blue:(c / 255.0) alpha:1.0]
#define RGBA(a, b, c, d) [UIColor colorWithRed:(a / 255.0) green:(b / 255.0) blue:(c / 255.0) alpha:d]

#ifdef DEBUG
#define TRACE(a, ...) NSLog(a, ##__VA_ARGS__)
#else
#define TRACE(a, ...)
#endif

#define LIBRARY_UPDATED_NOTIFICATION @"WCLibraryUpdatedNotification"

#endif
