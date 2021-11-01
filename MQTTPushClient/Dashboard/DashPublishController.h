/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>
#import "DashItem.h"

@protocol DashPublishController
-(uint32_t)publish:(NSString *)topic payload:(NSData *)payload retain:(BOOL)retain item:(DashItem *)item;
@end
