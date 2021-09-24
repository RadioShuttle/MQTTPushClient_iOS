/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashMessage.h"
#import "NSDictionary+HelSafeAccessors.h"

@implementation DashMessage

-(instancetype)initWithJSON:(NSDictionary *) dict {
	if (self = [super init]) {
		NSTimeInterval ts = [[dict helNumberForKey:@"timestamp"] doubleValue] ;
		self.timestamp = [NSDate dateWithTimeIntervalSince1970:ts];
		self.messageID = [[dict helNumberForKey:@"messageID"] intValue];
		self.topic = [dict helStringForKey:@"topic"];
		NSString *base64Str = [dict helStringForKey:@"content"];
		self.content = [[NSData alloc] initWithBase64EncodedString:base64Str options:0];
		self.status = [[dict helNumberForKey:@"status"] intValue] ;
	}
	return self;
}

-(NSDictionary *)toJSON {
	NSMutableDictionary *dict = [NSMutableDictionary new];
	[dict setObject:[NSNumber numberWithDouble:[self.timestamp timeIntervalSince1970]] forKey:@"timestamp"];
	
	[dict setObject:[NSNumber numberWithInteger:self.messageID] forKey:@"messageID"];
	[dict setObject:self.topic forKey:@"topic"];
	
	NSData *base64 = [self.content base64EncodedDataWithOptions:0];
	NSString * contentStr = [[NSString alloc]initWithData:base64 encoding:NSUTF8StringEncoding];
	[dict setObject:contentStr forKey:@"content"];
	[dict setObject:[NSNumber numberWithInteger:self.messageID] forKey:@"status"];

	return dict;
}

@end
