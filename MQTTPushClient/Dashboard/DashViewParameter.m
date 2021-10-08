/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashViewParameter.h"
#import "DashUtils.h"
#import "Utils.h"
#import "DashConsts.h"
#import "DashTextItem.h"
#import "DashSwitchItem.h"
#import "DashSliderItem.h"
#import "DashOptionItem.h"

@protocol DashJSViewExports <JSExport>
- (void)setTextSize:(int)textsize;
- (int)getTextSize;
- (void)setBackgroundColor:(int64_t)color;
- (int64_t)getBackgroundColor;
- (void)setBackgroundImage:(NSString *)resourceName;
- (NSString *)getBackgroundImage;
- (NSString *)getSubscribedTopic;
- (NSString *)getPublishedTopic;
- (void)setCtrlColor:(int64_t)color;
- (int64_t)getCtrlColor;
- (void)setCtrlBackground:(int64_t)color;
- (int64_t)getCtrlBackground;
- (void)setCtrlImage:(NSString *)resourceName;
- (NSString *)getCtrlImage;
- (void)setCtrlColorOff:(int64_t)color;
- (int64_t)getCtrlColorOff;
- (void)setBackgroundOff:(int64_t)color;
- (int64_t)getCtrlBackgroundOff;
- (void)setCtrlImageOff:(NSString *)resourceName;
- (NSString *)getCtrlImageOff;
- (NSDictionary *)getUserData;
- (void)setUserData:(NSDictionary *)userData;

@end

@interface  DashViewParameter () <DashJSViewExports>
@end

@interface DashTextItemViewParameter : DashViewParameter
@end

@interface DashSwitchItemViewParameter : DashViewParameter
@end

@interface DashSliderItemViewParameter : DashViewParameter
@end

@interface DashOptionItemViewParameter : DashViewParameter
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

+(instancetype)viewParameterWithItem:(DashItem *)item context:(JSContext *)context account:(Account *)account {
	DashViewParameter *para;
	if ([item class] == [DashTextItem class]) {
		para = [[DashTextItemViewParameter alloc]initWithItem:item context:context account:account];
	} else if ([item class] == [DashSwitchItem class]) {
		para = [[DashSwitchItemViewParameter alloc]initWithItem:item context:context account:account];
	} else if ([item class] == [DashSliderItem class]) {
		para = [[DashSliderItemViewParameter alloc]initWithItem:item context:context account:account];
	} else if ([item class] == [DashOptionItem class]) {
		para = [[DashOptionItemViewParameter alloc]initWithItem:item context:context account:account];
	} else {
		para = [[DashViewParameter alloc]initWithItem:item context:context account:account];
	}
	return para;
}

- (void)setTextColor:(int64_t)color {
}
- (int64_t)getTextColor {
	return DASH_COLOR_OS_DEFAULT;
}
- (void)setTextSize:(int)textsize {
}
- (int)getTextSize {
	return 0;
}
- (void)setBackgroundColor:(int64_t)color {
	self.dashItem.background = color;
}
- (int64_t)getBackgroundColor {
	return self.dashItem.background;
}

- (void)setBackgroundImage:(NSString *)resourceName {
	@try {
		self.dashItem.background_uri = [self uriForResourceName:resourceName];
	} @catch(NSException *exception) {
	}
}
- (NSString *)getBackgroundImage {
	return [self convertToJSResourceName:self.dashItem.background_uri];
}

- (NSString *)getSubscribedTopic {
	return self.dashItem.topic_s;
}

- (NSString *)getPublishedTopic {
	return self.dashItem.topic_p;
}

- (void)setCtrlColor:(int64_t)color {
}

- (int64_t)getCtrlColor {
	return DASH_COLOR_OS_DEFAULT;
}

- (void)setCtrlBackground:(int64_t)color {
}

- (int64_t)getCtrlBackground {
	return DASH_COLOR_OS_DEFAULT;
}

- (void)setCtrlImage:(NSString *)resourceName {
}

- (NSString *)getCtrlImage {
	return nil;
}

- (NSDictionary *)getUserData {
	return self.dashItem.userData;
}

- (void)setUserData:(NSDictionary *)userData {
	self.dashItem.userData = userData;
}

- (void)setCtrlColorOff:(int64_t)color {
}

- (int64_t)getCtrlColorOff {
	return DASH_COLOR_OS_DEFAULT;
}

- (void)setBackgroundOff:(int64_t)color {
}

- (int64_t)getCtrlBackgroundOff {
	return DASH_COLOR_OS_DEFAULT;
}

- (void)setCtrlImageOff:(NSString *)resourceName {
}

- (NSString *)getCtrlImageOff {
	return nil;
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

/* throws exception when invalid resource name and also sets self.jsContext.exception */
- (NSString *)uriForResourceName:(NSString *)resourceName {
	NSString *res = nil;
	if (![Utils isEmpty:resourceName]) {
		if ([[resourceName lowercaseString] hasPrefix:@"tmp/"]) {
			NSString *msg = [NSString stringWithFormat:@"Using temp resources is not allowed: %@", resourceName];
			self.jsContext.exception = [JSValue valueWithNewErrorFromMessage:msg inContext:self.jsContext];
			@throw [NSException exceptionWithName:NSInvalidArgumentException reason:msg userInfo:nil];
		}
		
		NSString *uri = [DashUtils getResourceURIFromResourceName:resourceName userDataDir:self.account.cacheURL];
		
		if ([Utils isEmpty:uri]) {
			NSString *msg = [NSString stringWithFormat:@"Image resource not found: %@", resourceName];
			self.jsContext.exception = [JSValue valueWithNewErrorFromMessage:msg inContext:self.jsContext];
			@throw [NSException exceptionWithName:NSInvalidArgumentException reason:msg userInfo:nil];
		}
		res = uri;
	} else {
		res = resourceName;
	}
	return res;
}


@end

@implementation DashTextItemViewParameter : DashViewParameter
- (void)setTextColor:(int64_t)color {
	self.dashItem.textcolor = color;
}
- (int64_t)getTextColor {
	return self.dashItem.textcolor;
}
- (void)setTextSize:(int)textsize {
	self.dashItem.textsize = textsize;
}
- (int)getTextSize {
	return self.dashItem.textsize;
}
@end

@implementation DashSwitchItemViewParameter : DashViewParameter
- (void)setCtrlColor:(int64_t)color {
	((DashSwitchItem *) self.dashItem).color = color;
}
- (int64_t)getCtrlColor {
	return ((DashSwitchItem *) self.dashItem).color;
}
- (void)setCtrlBackground:(int64_t)color {
	((DashSwitchItem *) self.dashItem).bgcolor = color;
}

- (int64_t)getCtrlBackground {
	return ((DashSwitchItem *) self.dashItem).bgcolor;
}

- (void)setCtrlImage:(NSString *)resourceName {
	@try {
		((DashSwitchItem *) self.dashItem).uri = [self uriForResourceName:resourceName];
	} @catch(NSException *exception) {
	}
}
- (NSString *)getCtrlImage {
	return [self convertToJSResourceName:((DashSwitchItem *) self.dashItem).uri];
}
- (void)setCtrlColorOff:(int64_t)color {
	((DashSwitchItem *) self.dashItem).colorOff = color;
}
- (int64_t)getCtrlColorOff {
	return ((DashSwitchItem *) self.dashItem).colorOff;
}
- (void)setCtrlImageOff:(NSString *)resourceName {
	@try {
		((DashSwitchItem *) self.dashItem).uriOff = [self uriForResourceName:resourceName];
	} @catch(NSException *exception) {
	}
}
- (NSString *)getCtrlImageOff {
	return [self convertToJSResourceName:((DashSwitchItem *) self.dashItem).uriOff];
}

@end

@implementation DashSliderItemViewParameter : DashViewParameter
- (void)setTextColor:(int64_t)color {
	self.dashItem.textcolor = color;
}
- (int64_t)getTextColor {
	return self.dashItem.textcolor;
}
- (void)setTextSize:(int)textsize {
	self.dashItem.textsize = textsize;
}
- (int)getTextSize {
	return self.dashItem.textsize;
}
- (void)setCtrlColor:(int64_t)color {
	((DashSliderItem *) self.dashItem).progresscolor = color;
}
- (int64_t)getCtrlColor {
	return ((DashSliderItem *) self.dashItem).progresscolor;
}

@end

@implementation DashOptionItemViewParameter : DashViewParameter
- (void)setTextColor:(int64_t)color {
	self.dashItem.textcolor = color;
}
- (int64_t)getTextColor {
	return self.dashItem.textcolor;
}
- (void)setTextSize:(int)textsize {
	self.dashItem.textsize = textsize;
}
- (int)getTextSize {
	return self.dashItem.textsize;
}
@end
