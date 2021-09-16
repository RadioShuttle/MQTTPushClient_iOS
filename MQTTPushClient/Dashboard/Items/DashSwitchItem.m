/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashSwitchItem.h"
#import "DashConsts.h"

@implementation DashSwitchItem

- (instancetype)init
{
    self = [super init];
    if (self) {
        _color = DASH_COLOR_OS_DEFAULT;
        _bgcolor = DASH_COLOR_OS_DEFAULT;
        _colorOff = DASH_COLOR_OS_DEFAULT;
        _bgcolorOff = DASH_COLOR_OS_DEFAULT;
    }
    return self;
}

-(BOOL)isOnState {
    return [self.valOff length] == 0 || [self.val isEqualToString:self.content];
}

@end
