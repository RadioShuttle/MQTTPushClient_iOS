/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import Foundation;
#import <WebKit/WebKit.h>
#import "DashItem.h"
#import "DashMessage.h"

@interface DashCustomItem : DashItem
@property NSString *html;
@property NSString *htmlUri;
@property NSArray<NSString *> *parameter;

/* last message received matching dash item's topic */
@property DashMessage *message;

@property BOOL reloadRequested;
@end
