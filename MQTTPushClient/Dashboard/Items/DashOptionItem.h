/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashItem.h"
#import "DashOptionListItem.h"

@interface DashOptionItem : DashItem
@property NSArray<DashOptionListItem *> *optionList;
@end
