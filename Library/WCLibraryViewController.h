//
//  WCLibraryViewController.h
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

@protocol WCLibraryViewControllerDelegate <NSObject>

- (void)comicItemSelected:(NSDictionary *)item;

@end


@interface WCLibraryViewController : UITableViewController

@property (nonatomic, weak) id<WCLibraryViewControllerDelegate> target;
@property (nonatomic, weak) NSMutableArray *dataSource;

@end
