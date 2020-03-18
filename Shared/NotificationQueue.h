/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>

@class NotificationQueue;

NS_ASSUME_NONNULL_BEGIN

@protocol NotificationQueueDelegate <NSObject>
- (void)directoryDidChange:(NotificationQueue *)notificationQueue;
@end

@interface NotificationQueue : NSObject

- (void)addNotification:(NSDictionary *)notification;
- (nullable NSArray<NSDictionary *>*)notifications;
- (BOOL)startWatchingWithDelegate:(id<NotificationQueueDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
