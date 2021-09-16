/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashItem.h"
#import "DashOptionListItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface DashOptionItem : DashItem
@property NSMutableArray<DashOptionListItem *> *optionList;
@end

NS_ASSUME_NONNULL_END
