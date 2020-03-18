/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>

enum NotificationType {
	NotificationDisabled,
	NotificationNone,
	NotificationBanner,
	NotificationBannerSound
};

@interface Topic : NSObject

@property(nonnull, copy) NSString *name;
@property enum NotificationType type;
@property(nullable, copy) NSString *filterScript;
@property(nullable, copy) NSString *filterScriptEdited;

// Reading from and writing to user defaults:
+ (nullable instancetype)topicFromUserDefaultsDict:(nonnull NSDictionary *)dict;
- (nonnull NSDictionary *)userDefaultsDict;

@end
