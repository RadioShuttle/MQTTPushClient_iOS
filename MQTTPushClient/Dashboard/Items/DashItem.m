/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "NSDictionary+HelSafeAccessors.h"

#import "DashConsts.h"
#import "DashItem.h"
#import "DashGroupItem.h"
#import "DashTextItem.h"
#import "DashSwitchItem.h"
#import "DashSliderItem.h"
#import "DashOptionItem.h"
#import "DashCustomItem.h"

@implementation DashItem

- (instancetype)init
{
	return [self initWithJSON:nil];
}

- (instancetype)initWithJSON:(NSDictionary *) dictObj {
	
	self = [super init];

	_textcolor = DASH_COLOR_OS_DEFAULT;
	_background = DASH_COLOR_OS_DEFAULT;

	if (dictObj) {
		self.id_ = [[dictObj helNumberForKey:@"id"] unsignedIntValue];
		self.textcolor = [[dictObj helNumberForKey:@"textcolor"] unsignedLongLongValue];
		self.background = [[dictObj helNumberForKey:@"background"] unsignedLongLongValue];
		self.textsize = [[dictObj helNumberForKey:@"textsize"] intValue];
		self.topic_s = [dictObj helStringForKey:@"topic_s"];
		self.script_f = [dictObj helStringForKey:@"script_f"];
		self.background_uri = [dictObj helStringForKey:@"background_uri"];
		
		self.topic_p = [dictObj helStringForKey:@"topic_p"];
		self.script_p = [dictObj helStringForKey:@"script_p"];
		self.retain_ = [[dictObj helNumberForKey:@"retain"] boolValue];
		self.label = [dictObj helStringForKey:@"label"];
		self.history = [[dictObj helNumberForKey:@"history"] boolValue];
	}
	
	return self;
}

+ (DashItem *)createObjectFromJSON:(NSDictionary *)dictObj {
	DashItem *item;
	NSString *type = [dictObj helStringForKey:@"type"];
	if ([type isEqualToString:@"group"]) {
		item = [[DashGroupItem alloc] initWithJSON:dictObj];
	} else if ([type isEqualToString:@"text"]) {
		item = [[DashTextItem alloc] initWithJSON:dictObj];
	} else if ([type isEqualToString:@"switch"]) {
		item = [[DashSwitchItem alloc] initWithJSON:dictObj];
	} else if ([type isEqualToString:@"progress"]) {
		item = [[DashSliderItem alloc] initWithJSON:dictObj];
	} else if ([type isEqualToString:@"optionlist"]) {
		item = [[DashOptionItem alloc] initWithJSON:dictObj];
	} else if ([type isEqualToString:@"custom"]) {
		item = [[DashCustomItem alloc] initWithJSON:dictObj];
	}
	return item;
}

@end
