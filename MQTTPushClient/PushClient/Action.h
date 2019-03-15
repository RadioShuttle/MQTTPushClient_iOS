/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>

@interface Action : NSObject

@property(copy) NSString *name;
@property(copy) NSString *topic;
@property(copy) NSString *content;
@property BOOL retainFlag;

@end
