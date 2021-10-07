/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashViewParameter.h"
#import "DashUtils.h"
#import "Utils.h"

@protocol DashJSViewExports <JSExport>
- (void)setBackgroundImage:(NSString *)resourceName;
- (NSString *)getBackgroundImage;

@end

@interface  DashViewParameter () <DashJSViewExports>
	
@end

@implementation DashViewParameter

-(instancetype)init {
	return [self initWithItem:nil context:nil account:nil];
}

-(instancetype)initWithItem:(DashItem *)item context:(JSContext *)context account:(Account *)account {
	self = [super init];
	self.dashItem = item;
	self.jsContext = context;
	self.account = account;
	return self;
}

- (void)setTextColor:(int64_t)color {
	self.dashItem.textcolor = color;
}
- (void)setBackgroundColor:(int64_t)color {
	self.dashItem.background = color;
}
- (int64_t)getTextColor {
	return self.dashItem.textcolor;
}
- (int64_t)getBackgroundColor {
	return self.dashItem.background;
}

- (NSString *)convertToJSResourceName:(NSString *)uri {
	NSString *jsResource = @"";
	if ([uri hasPrefix:@"res://internal/"]) {
		jsResource = [NSString stringWithFormat:@"int/%@", [uri substringFromIndex:15]];
	} else if ([uri hasPrefix:@"res://user/"]) {
		jsResource = [NSString stringWithFormat:@"user/%@", [uri substringFromIndex:11]];
	}
	return jsResource;
}

- (void)setBackgroundImage:(NSString *)resourceName {
	if (![Utils isEmpty:resourceName]) {
		if ([[resourceName lowercaseString] hasPrefix:@"tmp/"]) {
			NSString *msg = [NSString stringWithFormat:@"Using temp resources is not allowed: %@", resourceName];
			self.jsContext.exception = [JSValue valueWithNewErrorFromMessage:msg inContext:self.jsContext];
			return;
		}
		
		NSString *uri = [DashUtils getResourceURIFromResourceName:resourceName userDataDir:self.account.cacheURL];
		
		if ([Utils isEmpty:uri]) {
			NSString *msg = [NSString stringWithFormat:@"Image resource not found: %@", resourceName];
			self.jsContext.exception = [JSValue valueWithNewErrorFromMessage:msg inContext:self.jsContext];
			return;
		}
		self.dashItem.background_uri = uri;
	} else {
		self.dashItem.background_uri = resourceName;
	}
}

- (NSString *)getBackgroundImage {
	return [self convertToJSResourceName:self.dashItem.background_uri];
}



@end
