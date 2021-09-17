/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import Foundation;
#import "DashItem.h"

@interface DashCustomItem : DashItem
@property NSString *html;
@property NSMutableArray<NSString *> *parameter;
@end
