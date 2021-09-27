/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashSwitchItem.h"
#import "DashConsts.h"
#import "NSDictionary+HelSafeAccessors.h"

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

@end
