/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashSwitchItem.h"
#import "DashConsts.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "Utils.h"
#import "DashUtils.h"

@implementation DashSwitchItem

- (instancetype)init
{
	return [self initWithJSON:nil];
}

- (instancetype)initWithJSON:(NSDictionary *) dictObj {
	self = [super initWithJSON:dictObj];
	
	self.color = DASH_COLOR_OS_DEFAULT;
	self.bgcolor = DASH_COLOR_OS_DEFAULT;
	self.colorOff = DASH_COLOR_OS_DEFAULT;
	self.bgcolorOff = DASH_COLOR_OS_DEFAULT;

	if (dictObj) {
	
		self.val = [dictObj helStringForKey:@"val"];
		self.uri = [dictObj helStringForKey:@"uri"];
		
		NSNumber *numVal = [dictObj helNumberForKey:@"color"];
		if (numVal) {
			self.color = [numVal unsignedLongLongValue];
		}
		numVal = [dictObj helNumberForKey:@"bgcolor"];
		if (numVal) {
			self.bgcolor = [numVal unsignedLongLongValue];
		}
		self.valOff = [dictObj helStringForKey:@"val_off"];
		self.uriOff = [dictObj helStringForKey:@"uri_off"];
		
		numVal = [dictObj helNumberForKey:@"color_off"];
		if (numVal) {
			self.colorOff = [numVal unsignedLongLongValue];
		}
		numVal = [dictObj helNumberForKey:@"bgcolor_off"];
		if (numVal) {
			self.bgcolorOff = [numVal unsignedLongLongValue];
		}
	}
	
	return self;
}

-(BOOL)isOnState {
	return [self.valOff length] == 0 || [self.val isEqualToString:self.content];
}

-(id)copyWithZone:(NSZone *)zone {
	DashSwitchItem *clone = [super copyWithZone:zone];
	clone.val = self.val;
	clone.color = self.color;
	clone.bgcolor = self.bgcolor;
	clone.uri = self.uri;
	
	clone.valOff = self.valOff;
	clone.colorOff = self.colorOff;
	clone.bgcolorOff = self.bgcolorOff;
	clone.uriOff = self.uriOff;

	return clone;
}

- (BOOL)isEqual:(id)other {
	BOOL eq = [super isEqual:other];
	if (eq) {
		DashSwitchItem *o = (DashSwitchItem *) other;
		
		eq = [Utils areEqual:self.val s2:o.val] && [DashUtils cmpColor:self.color color:o.color] && [DashUtils cmpColor:self.bgcolor color:o.bgcolor] && [Utils areEqual:self.uri s2:o.uri] && [Utils areEqual:self.valOff s2:o.valOff] && [DashUtils cmpColor:self.colorOff color:o.colorOff] && [DashUtils cmpColor:self.bgcolorOff color:o.bgcolorOff] && [Utils areEqual:self.uriOff s2:o.uriOff];
	}
	return eq;
}

- (NSDictionary *)toJSONObject {
	NSMutableDictionary *o = (NSMutableDictionary *) [super toJSONObject];
	[o setObject:@"switch" forKey:@"type"];
	
	[o setObject:self.val ? self.val : @"" forKey:@"val"];
	[o setObject:self.uri ? self.uri : @"" forKey:@"uri"];
	[o setObject:[NSNumber numberWithLongLong:self.color] forKey:@"color"];
	[o setObject:[NSNumber numberWithLongLong:self.bgcolor] forKey:@"bgcolor"];

	[o setObject:self.valOff ? self.valOff : @"" forKey:@"val_off"];
	[o setObject:self.uriOff ? self.uriOff : @"" forKey:@"uri_off"];
	[o setObject:[NSNumber numberWithLongLong:self.colorOff] forKey:@"color_off"];
	[o setObject:[NSNumber numberWithLongLong:self.bgcolorOff] forKey:@"bgcolor_off"];

	return o;
}

@end
