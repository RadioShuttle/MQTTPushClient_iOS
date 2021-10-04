/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashItem.h"

@interface DashSwitchItem : DashItem
@property NSString *val;
@property int64_t color; // ctrl tint color
@property int64_t bgcolor; // ctrl background color
@property NSString *uri; // res://internal/ic_alarm

@property NSString *valOff; // off state (if switch), unused if button
@property uint64_t colorOff;
@property uint64_t bgcolorOff;
@property NSString *uriOff;

-(BOOL)isOnState;

@end
