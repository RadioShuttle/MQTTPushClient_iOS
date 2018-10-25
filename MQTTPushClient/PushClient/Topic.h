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

@property NSString *name;
@property enum NotificationType type;

@end
