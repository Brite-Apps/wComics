/**
 * @class WCComic
 */

@class ZKDataArchive, Unrar4iOS;

typedef enum {
	WCZipFile = 1,
	WCRarFile = 2,
	WCNone = 3
} WCArchType;

@interface WCComic : NSObject {
	__strong ZKDataArchive *archive;
	Unrar4iOS *rarArchive;
	NSMutableArray *filesList;
	WCArchType archType;
}

@property (nonatomic, strong) NSString *file;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, readonly) NSInteger numberOfPages;

+ (void)createCoverImageForFile:(NSString *)path;
- (id)initWithFile:(NSString *)aFile;
- (UIImage *)imageAtIndex:(int)index;
- (void)close;
- (BOOL)somewhereInSubdir:(NSString *)dir;

@end
