//
//  Message.m
//  MQTTPushClient
//
//  Created by admin on 11/5/18.
//  Copyright © 2018 Helios. All rights reserved.
//

#import "Message.h"

@implementation Message

-(BOOL) isNewerThan:(Message *)other {
	if (other == nil || other.timestamp == nil) {
		return YES;
	}
	switch ([self.timestamp compare:other.timestamp]) {
		case NSOrderedAscending:
			return NO;
		case NSOrderedSame:
			return self.messageID > other.messageID;
		case NSOrderedDescending:
			return YES;
	}
}

@end
