/**
 * @class WCItemCell
 * @author Nik S Dyonin <nik@brite-apps.com>
 */

#import "WCItemCell.h"

@implementation WCItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) != nil) {
		self.textLabel.font = [UIFont boldSystemFontOfSize:18];
		self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
		self.textLabel.numberOfLines = 1;
		
		self.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	return self;
}

- (void)setItem:(NSDictionary *)aItem {
	if (_item != aItem) {
		_item = aItem;

		if (_item) {
			@autoreleasepool {
				NSString *itemPath = _item[@"path"];
				BOOL isDir = [_item[@"dir"] boolValue];
				
				if (isDir) {
					self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					self.imageView.image = [UIImage imageNamed:@"folder"];
					[self.imageView sizeToFit];
				}
				else {
					self.accessoryType = UITableViewCellAccessoryNone;
					
					NSString *coverFile = [[NSString alloc] initWithFormat:@"%@/covers/%@_wcomics_cover_file", DOCPATH, [itemPath lastPathComponent]];
					if ([[NSFileManager defaultManager] fileExistsAtPath:coverFile]) {
						UIImage *cover = [[UIImage alloc] initWithContentsOfFile:coverFile];
						if (cover && cover.size.width) {
							self.imageView.image = cover;
						}
						else {
							self.imageView.image = [UIImage imageNamed:@"document"];
						}
					}
					else {
						self.imageView.image = [UIImage imageNamed:@"document"];
					}
					[self.imageView sizeToFit];
				}

				NSMutableString *titleStr = [[NSMutableString alloc] initWithString:[[_item[@"path"] componentsSeparatedByString:@"/"] lastObject]];
				[titleStr replaceOccurrencesOfString:@".cbz" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [titleStr length])];
				[titleStr replaceOccurrencesOfString:@".cbr" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [titleStr length])];
				self.textLabel.text = titleStr;
			}
		}
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGRect tmpRect = self.imageView.frame;
	tmpRect.origin.x = 8.0f + floorf((31.0f - tmpRect.size.width) / 2.0f);
	tmpRect.origin.y = floorf((44.0f - tmpRect.size.height) / 2.0f);
	self.imageView.frame = tmpRect;
	
	tmpRect.origin.x = self.imageView.frame.origin.x + 31.0f + 10.0f;
	tmpRect.origin.y = 0.0f;
	tmpRect.size.width = 421.0f;
	tmpRect.size.height = 43.0f;
	self.textLabel.frame = tmpRect;
}

- (void)dealloc {
	self.item = nil;
}

@end
