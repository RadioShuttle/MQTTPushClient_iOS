/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashItem.h"

@interface DashTextItem : DashItem
@property int inputtype;

/* will be shown in items input field in detail view, when set via filter script */
@property NSString *defaultValue;
@end
