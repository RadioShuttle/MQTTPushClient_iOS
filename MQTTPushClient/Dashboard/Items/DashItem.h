/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import Foundation;

@interface DashItem : NSObject

@property uint32_t id_;
@property uint64_t textcolor;
@property uint64_t background;
@property int textsize;
@property NSString *topic_s;
@property NSString *script_f;
@property NSString *background_uri;

@property NSString *topic_p;
@property NSString *script_p;
@property BOOL retain_;
@property NSString *label;
@property BOOL history;

- (instancetype)initWithJSON:(NSDictionary *)dictObj;

+ (DashItem *)createObjectFromJSON:(NSDictionary *)jobj;

@end
