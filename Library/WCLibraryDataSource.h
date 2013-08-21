/**
 * @class WCLibraryDataSource
 */

@interface WCLibraryDataSource : NSObject

@property (nonatomic, readonly) NSMutableArray *library;

+ (WCLibraryDataSource *)sharedInstance;
- (void)updateLibrary;

@end
