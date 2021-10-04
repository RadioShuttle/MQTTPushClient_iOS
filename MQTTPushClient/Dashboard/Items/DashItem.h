/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import Foundation;
@import UIKit;

@interface DashItem : NSObject

@property uint32_t id_;
@property int64_t textcolor;
@property int64_t background;
@property int textsize;
@property NSString *topic_s;
@property NSString *script_f;
@property NSString *background_uri;

@property NSString *topic_p;
@property NSString *script_p;
@property BOOL retain_;
@property NSString *label;
@property BOOL history;

@property NSString *content;

- (instancetype)initWithJSON:(NSDictionary *)dictObj;

+ (DashItem *)createObjectFromJSON:(NSDictionary *)dictObj;

@end
