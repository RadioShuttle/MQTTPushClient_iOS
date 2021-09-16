/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashOptionItem.h"

@implementation DashOptionItem

- (instancetype)init
{
    self = [super init];
    if (self) {
        _optionList = [NSMutableArray new];
    }
    return self;
}

@end
