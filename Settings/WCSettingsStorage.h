/**
 * @class WCSettingsStorage
 */

@interface WCSettingsStorage : NSObject {
	NSUserDefaults *settings;
}

@property (nonatomic, assign, setter=setLastDocument:, getter=lastDocument) NSString *lastDocument;

+ (WCSettingsStorage *)sharedInstance;
- (unsigned int)currentPageForFile:(NSString *)file;
- (void)saveCurrentPage:(unsigned int)page forFile:(NSString *)file;
- (void)removeSettingsForFile:(NSString *)file;

@end
