/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>
#import "Action.h"
#import "Cmd.h"
#import "Dashboard.h"

@interface Connection : NSObject

- (Cmd *)login:(Account *)account withMqttPassword:(NSString *)password secureTransport:(BOOL)secureTransport;
- (void)getFcmDataForAccount:(Account *)account;
- (void)removeDeviceForAccount:(Account *)account;
- (void)getMessagesForAccount:(Account *)account;
- (void)publishMessageForAccount:(Account *)account action:(Action *)action;
- (void)getTopicsForAccount:(Account *)account;
- (void)addTopicForAccount:(Account *)account name:(NSString *)name type:(enum NotificationType)type
			  filterScript:(NSString *)filterScript;
- (void)updateTopicForAccount:(Account *)account name:(NSString *)name type:(enum NotificationType)type
				 filterScript:(NSString *)filterScript;
- (void)deleteTopicForAccount:(Account *)account name:(NSString *)name;
- (void)getActionsForAccount:(Account *)account;
- (void)addActionForAccount:(Account *)account action:(Action *)action;
- (void)updateActionForAccount:(Account *)account action:(Action *)action name:(NSString *)name;
- (void)deleteActionForAccount:(Account *)account name:(NSString *)name;
- (void)getDashboardForAccount:(Dashboard *)dashboard;
-(int)activeDashboardRequests;
- (void)publishMessageForAccount:(Account *)account topic:(NSString *)topic payload:(NSData *)payload retain:(BOOL)retain userInfo:(NSDictionary *)userInfo;

@end
