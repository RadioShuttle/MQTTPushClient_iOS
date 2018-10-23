/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>
#import "Cmd.h"

@interface Connection : NSObject

- (Cmd *)login:(Account *)account withMqttPassword:(NSString *)password;
- (void)getFcmDataForAccount:(Account *)account;
- (void)getTopicsForAccount:(Account *)account;

@end
