/**
 * @class WCSettingsStorage
 * @author Nik Dyonin <wolf.step@gmail.com>
 */

static NSString *settingsMutex = @"settingsMutex";

#import "WCSettingsStorage.h"

@implementation WCSettingsStorage

+ (WCSettingsStorage *)sharedInstance {
	static WCSettingsStorage *sharedInstance;
	@synchronized (settingsMutex) {
		if (sharedInstance == nil) {
			@synchronized (settingsMutex)
			{
				sharedInstance = [[WCSettingsStorage alloc] init];
			}
		}
	}
	return sharedInstance;
}

- (id)init {
	if ((self = [super init]) != nil) {
		settings = [NSUserDefaults standardUserDefaults];
	}
	return self;
}

- (unsigned int)currentPageForFile:(NSString *)file {
	return [[[settings objectForKey:@"states"] objectForKey:file] unsignedIntValue];
}

- (void)saveCurrentPage:(unsigned int)page forFile:(NSString *)file {
	@try {
		NSMutableDictionary *states = [[NSMutableDictionary alloc] initWithDictionary:[settings objectForKey:@"states"]];
		NSNumber *num = @(page);
		[states setObject:num forKey:file];
		[settings setObject:states forKey:@"states"];
	}
	@catch (NSException *e) {
		TRACE(@"WCSettingsStorage (-saveCurrentPage:forFile:) exception caught: %@", e);
	}
}

- (NSString *)lastDocument {
	return [settings stringForKey:@"lastDocument"];
}

- (void)setLastDocument:(NSString *)document {
	@try {
		if (document) {
			[settings setObject:document forKey:@"lastDocument"];
		}
		else {
			[settings removeObjectForKey:@"lastDocument"];
		}
	}
	@catch (NSException *e) {
		TRACE(@"WCSettingsStorage (-setLastDocument:) exception caught: %@", e);
	}
}

- (void)removeSettingsForFile:(NSString *)file {
	@try {
		NSMutableDictionary *states = [[NSMutableDictionary alloc] initWithDictionary:[settings objectForKey:@"states"]];
		[states removeObjectForKey:file];
		[settings setObject:states forKey:@"states"];
	}
	@catch (NSException *exception) {
		TRACE(@"WCSettingsStorage (-removeSettingsForFile:) caught exception: %@", exception);
	}
}

@end
