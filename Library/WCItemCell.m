//
//  WCItemCell.m
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCItemCell.h"
#import "WCComic.h"
#import "Common.h"

@implementation WCItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) != nil) {
		self.textLabel.font = [UIFont systemFontOfSize:18];
		self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
		self.textLabel.numberOfLines = 1;
		
		self.imageView.contentMode = UIViewContentModeScaleAspectFit;
		
		self.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	return self;
}

- (void)setItem:(NSDictionary *)aItem {
	if (_item != aItem) {
		_item = aItem;

		if (_item) {
			NSString *itemPath = _item[@"path"];
			BOOL isDir = [_item[@"dir"] boolValue];
			
			if (isDir) {
				self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				self.imageView.image = [UIImage imageNamed:@"folder"];
			}
			else {
				self.accessoryType = UITableViewCellAccessoryNone;
				
				__block NSString *coverFile = [[NSString alloc] initWithFormat:@"%@/covers/%@_wcomics_cover_file", DOCPATH, [itemPath lastPathComponent]];
				
				if ([[NSFileManager defaultManager] fileExistsAtPath:coverFile]) {
					UIImage *cover = [[UIImage alloc] initWithData:[NSData dataWithContentsOfFile:coverFile] scale:[UIScreen mainScreen].scale];
					
					if (cover && cover.size.width) {
						self.imageView.image = cover;
					}
					else {
						self.imageView.image = [UIImage imageNamed:@"document"];
					}
				}
				else {
					self.imageView.image = [UIImage imageNamed:@"document"];
					
					__weak typeof(self.imageView) weakImageView = self.imageView;
					
					[WCComic
					 createCoverImageForPath:_item[@"path"]
					 withCallback:^(UIImage *image, NSString *file) {
						 if (image &&[file isEqualToString:coverFile]) {
							 weakImageView.image = image;
						 }
					 }];
				}
			}
			
			NSString *title = [_item[@"path"] lastPathComponent];
			
			if (!isDir) {
				title = [title stringByDeletingPathExtension];
			}
			
			self.textLabel.text = title;
		}
	}
	
	[self setNeedsLayout];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	const CGFloat xOffset = self.textLabel.frame.origin.x - (self.imageView.frame.origin.x + self.imageView.bounds.size.width);
	
	CGRect frame = self.imageView.frame;
	frame.size.width = 32.0;
	self.imageView.frame = frame;
	
	frame = self.textLabel.frame;
	frame.origin.x = self.imageView.frame.origin.x + self.imageView.bounds.size.width + xOffset;
	self.textLabel.frame = frame;
}

- (void)dealloc {
	self.item = nil;
}

@end
