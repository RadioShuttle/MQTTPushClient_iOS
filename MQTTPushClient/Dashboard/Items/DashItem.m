/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashItem.h"
#import "DashConsts.h"

@implementation DashItem

- (instancetype)init
{
    self = [super init];
    if (self) {
        _textcolor = DASH_COLOR_OS_DEFAULT;
        _background = DASH_COLOR_OS_DEFAULT;
    }
    return self;
}

@end
