/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashGroupItem.h"

@implementation DashGroupItem

- (NSDictionary *)toJSONObject {
	NSMutableDictionary *o = (NSMutableDictionary *) [super toJSONObject];
	[o setObject:@"group" forKey:@"type"];
	return o;
}

@end
