/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>

@interface Action : NSObject

@property NSString *name;
@property NSString *topic;
@property NSString *content;
@property BOOL retainFlag;

@end
