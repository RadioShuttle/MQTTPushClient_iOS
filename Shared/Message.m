/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

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

+ (NSString *)msgFromData:(NSData *)data {
	NSString *msg;

	// Try auto-detection (with preference to UTF-8):
	NSDictionary *opts = @{NSStringEncodingDetectionSuggestedEncodingsKey :
							   @[@(NSUTF8StringEncoding)]};
	NSStringEncoding enc = [NSString stringEncodingForData:data
										   encodingOptions:opts convertedString:&msg usedLossyConversion:NULL];
	if (enc != 0) {
		return msg;
	}
	
	// Fallback:
	return [NSString stringWithFormat:@"%*.*s",
			(int)data.length, (int)data.length, data.bytes];
}

@end
