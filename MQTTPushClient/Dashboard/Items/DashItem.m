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
#import "Utils.h"
#import "DashUtils.h"

@implementation DashItem

- (instancetype)init
{
	return [self initWithJSON:nil];
}

- (instancetype)initWithJSON:(NSDictionary *) dictObj {
	
	self = [super init];

	self.textcolor = DASH_COLOR_OS_DEFAULT;
	self.background = DASH_COLOR_OS_DEFAULT;

	if (dictObj) {
		NSNumber *numVal;
		numVal = [dictObj helNumberForKey:@"id"];
		if (!numVal) {
			return nil;
		}
		self.id_ = [numVal unsignedIntValue];
		
		numVal = [dictObj helNumberForKey:@"textcolor"];
		if (numVal) {
			self.textcolor = [numVal unsignedLongLongValue];
		}
		numVal = [dictObj helNumberForKey:@"background"];
		if (numVal) {
			self.background = [numVal unsignedLongLongValue];
		}
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

-(id)copyWithZone:(NSZone *)zone {
	DashItem *clone = [[[self class] alloc] init];
	clone.id_ = self.id_;
	clone.textcolor = self.textcolor;
	clone.background = self.background;
	clone.textsize = self.textsize;
	clone.topic_s = self.topic_s;
	clone.script_f = self.script_f;
	clone.background_uri = self.background_uri;
	clone.topic_p = self.topic_p;
	clone.script_p = self.script_p;
	clone.retain_ = self.retain_;
	clone.label = self.label;
	clone.history = self.history;
	return clone;
}

- (BOOL)isEqual:(id)other {
	BOOL eq = NO;
	if ([other isKindOfClass:[DashItem class]]) {
		if (self == other) {
			eq = YES;
		} else {
			DashItem *o = (DashItem *)other;
			eq = self.id_ == o.id_ && [DashUtils cmpColor:self.textcolor color:o.textcolor] && [DashUtils cmpColor:self.background color:o.background] && self.textsize == o.textsize && self.retain_ == o.retain_ && self.history == o.history && [Utils areEqual:self.topic_s s2:o.topic_s] && [Utils areEqual:self.script_f s2:o.script_f] && [Utils areEqual:self.background_uri s2:o.background_uri] && [Utils areEqual:self.topic_p s2:o.topic_p] && [Utils areEqual:self.script_p s2:o.script_p] && [Utils areEqual:self.label s2:o.label];
		}
	}
	return eq;
}

@end
