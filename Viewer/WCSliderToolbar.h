//
//  WCSliderToolbar.h
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

@interface WCSliderToolbar : UIView

@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, assign) NSInteger totalPages;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;

@end
