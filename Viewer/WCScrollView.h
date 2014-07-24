//
//  WCScrollView.h
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

@interface WCScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, assign) UIView *viewForZoom;
@property (nonatomic, assign) CGRect pageRect;

@end
