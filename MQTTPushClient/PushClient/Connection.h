/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>
#import "Action.h"
#import "Cmd.h"

@interface Connection : NSObject

- (Cmd *)login:(Account *)account withMqttPassword:(NSString *)password secureTransport:(BOOL)secureTransport;
- (void)getFcmDataForAccount:(Account *)account;
- (void)removeTokenForAccount:(Account *)account;
- (void)getMessagesForAccount:(Account *)account;
- (void)publishMessageForAccount:(Account *)account action:(Action *)action;
- (void)getTopicsForAccount:(Account *)account;
- (void)addTopicForAccount:(Account *)account name:(NSString *)name type:(enum NotificationType)type;
- (void)updateTopicForAccount:(Account *)account name:(NSString *)name type:(enum NotificationType)type;
- (void)deleteTopicForAccount:(Account *)account name:(NSString *)name;
- (void)getActionsForAccount:(Account *)account;
- (void)addActionForAccount:(Account *)account action:(Action *)action;
- (void)updateActionForAccount:(Account *)account action:(Action *)action name:(NSString *)name;
- (void)deleteActionForAccount:(Account *)account name:(NSString *)name;

@end
