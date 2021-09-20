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
	
	_color = DASH_COLOR_OS_DEFAULT;
	_bgcolor = DASH_COLOR_OS_DEFAULT;
	_colorOff = DASH_COLOR_OS_DEFAULT;
	_bgcolorOff = DASH_COLOR_OS_DEFAULT;

	if (dictObj) {
		self.val = [dictObj helStringForKey:@"val"];
		self.uri = [dictObj helStringForKey:@"uri"];
		self.color = [[dictObj helNumberForKey:@"color"] unsignedLongLongValue];
		self.bgcolor = [[dictObj helNumberForKey:@"bgcolor"] unsignedLongLongValue];
		self.valOff = [dictObj helStringForKey:@"val_Off"];
		self.uriOff = [dictObj helStringForKey:@"uri_off"];
		self.colorOff = [[dictObj helNumberForKey:@"color_off"] unsignedLongLongValue];
		self.bgcolorOff = [[dictObj helNumberForKey:@"bgcolor_off"] unsignedLongLongValue];
	}
	
	return self;
}

-(BOOL)isOnState {
	return NO; // [self.valOff length] == 0 || [self.val isEqualToString:self.content]; //TODO
}

@end
