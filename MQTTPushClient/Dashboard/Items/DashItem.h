/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import Foundation;
@import UIKit;
#import "DashMessage.h"

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

/* last message received (timestamp) matching dash item's topic */
@property NSDate *lastMsgTimestamp;
@property NSString *content; // == message content or result of filter script
@property NSString* error1; // filter script errors (input)
@property NSString* error2; // publish errors (outptut)
@property NSDictionary* userData; // javascript user data

- (instancetype)initWithJSON:(NSDictionary *)dictObj;

+ (DashItem *)createObjectFromJSON:(NSDictionary *)dictObj;

@end
