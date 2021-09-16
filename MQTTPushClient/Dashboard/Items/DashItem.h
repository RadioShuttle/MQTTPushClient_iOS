/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import Foundation;

@interface DashItem : NSObject
@property int item_id;
@property NSString *label;
@property NSString *type;
@property NSString *content;

@property int64_t textcolor;
@property int64_t background;

@end
