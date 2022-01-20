/*
* Copyright (c) 2022 HELIOS Software GmbH
* 30827 Garbsen (Hannover) Germany
* Licensed under the Apache License, Version 2.0
*/

#import <Foundation/Foundation.h>
#import "DashItem.h"

@protocol DashItemViewContainer <NSObject>

-(void)onUpdate:(DashItem *)item what:(NSString *)what;

@end
