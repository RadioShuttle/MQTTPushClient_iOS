/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>

@interface DashOptionListItem : NSObject <NSCopying>
@property NSString *value;
@property NSString *displayValue;
@property NSString *imageURI;

- (instancetype)initWithJSON:(NSDictionary *) dictObj;

- (NSDictionary *)toJSONObject;

@end
