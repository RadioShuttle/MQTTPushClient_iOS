/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>

@class NotificationQueue;

@protocol NotificationQueueDelegate <NSObject>
- (void)directoryDidChange:(NotificationQueue *)notificationQueue;
@end


NS_ASSUME_NONNULL_BEGIN

@interface NotificationQueue : NSObject

- (void)addNotification:(NSDictionary *)notification;
- (nullable NSArray<NSDictionary *>*)notifications;
- (BOOL)startWatchingWithDelegate:(id<NotificationQueueDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
