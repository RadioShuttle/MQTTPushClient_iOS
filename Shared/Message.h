/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Message : NSObject

@property NSDate *timestamp;
@property int32_t messageID;
@property NSString *topic;
@property NSString *content;

-(BOOL) isNewerThan:(Message *)other;

@end

NS_ASSUME_NONNULL_END
