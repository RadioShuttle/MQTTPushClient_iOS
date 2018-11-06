//
//  Message.h
//  MQTTPushClient
//
//  Created by admin on 11/5/18.
//  Copyright © 2018 Helios. All rights reserved.
//

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
