/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>

enum NotificationType {
	NotificationDisabled,
	NotificationNone,
	NotificationBanner,
	NotificationBannerSound
};

@interface Topic : NSObject

@property(copy) NSString *name;
@property enum NotificationType type;
@property(copy) NSString *filterScript;
@property(copy) NSString *filterScriptEdited;

// Reading from and writing to user defaults:
+ (nullable instancetype)topicFromUserDefaultsDict:(NSDictionary *)dict;
- (NSDictionary *)userDefaultsDict;

@end
