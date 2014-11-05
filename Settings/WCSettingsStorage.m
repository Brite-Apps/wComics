//
//  WCSettingsStorage.m
//  wComics
//
//  Created by Nik Dyonin on 22.08.13.
//  Copyright (c) 2013 Nik Dyonin. All rights reserved.
//

#import "WCSettingsStorage.h"
#import "Common.h"

@implementation WCSettingsStorage {
	NSUserDefaults *settings;
}

+ (instancetype)sharedInstance {
	static dispatch_once_t pred;
	static WCSettingsStorage *shared = nil;
	dispatch_once(&pred, ^{
		shared = [[self alloc] init];
	});
	return shared;
}

- (id)init {
	if ((self = [super init]) != nil) {
		settings = [NSUserDefaults standardUserDefaults];
	}
	return self;
}

- (NSUInteger)currentPageForFile:(NSString *)file {
	return [[[settings objectForKey:@"states"] objectForKey:file] unsignedIntegerValue];
}

- (void)saveCurrentPage:(NSInteger)page forFile:(NSString *)file {
	@try {
		NSMutableDictionary *states = [[NSMutableDictionary alloc] initWithDictionary:[settings objectForKey:@"states"]];
		states[file] = @(page);
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
