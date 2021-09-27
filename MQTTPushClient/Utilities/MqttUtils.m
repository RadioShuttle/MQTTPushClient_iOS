/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "MqttUtils.h"

@implementation MqttUtils

+(void) topicValidate:(NSString *)topic wildcardAllowed:(BOOL)wildcardAllowed {
	NSUInteger len = [[topic dataUsingEncoding:NSUTF8StringEncoding] length];
	if (len < 1 || len > 65535) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid topic length" userInfo:nil];
	}
	if (!wildcardAllowed) {
		if ([topic rangeOfString:@"+"].location != NSNotFound || [topic rangeOfString:@"#"].location != NSNotFound) {
			@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Wildcards are not allowed" userInfo:nil];
		}
	} else if ([topic isEqualToString:@"+"] || [topic isEqualToString:@"#"]) {
		;
	} else {
		NSUInteger noOfWildcards = [[topic componentsSeparatedByString:@"#"] count] - 1;
		if (noOfWildcards > 1) {
			@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Only one wildcard # allowed" userInfo:nil];
		} else if (noOfWildcards == 1 && ![topic hasSuffix:@"/#"]) {
			@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid usage of wildcard #" userInfo:nil];
		}
		for(int i = 0; i < topic.length; i++) {
			if ([topic characterAtIndex:i] == '+') {
				if (i > 0) {
					if ([topic characterAtIndex:i - 1] != '/') {
						@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid usage of wildcard +" userInfo:nil];
					}
				}
				if (i + 1 < topic.length) {
					if ([topic characterAtIndex:i + 1] != '/') {
						@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid usage of wildcard +" userInfo:nil];
					}
				}
			}
		}
	}
}

+(BOOL) topicIsMatched:(NSString *)filter topic:(NSString *)topic {
	[MqttUtils topicValidate:filter wildcardAllowed:YES];
	[MqttUtils topicValidate:topic wildcardAllowed:NO];
	
	NSMutableArray<NSString *> *filterNodes = [NSMutableArray new];
	int i, pos = 0;
	for(i = 0; i < filter.length; i++) {
		if ([filter characterAtIndex:i] == '/') {
			[filterNodes addObject:[filter substringWithRange:NSMakeRange(pos, i - pos)]];
			pos = i + 1;
		}
	}
	[filterNodes addObject:[filter substringWithRange:NSMakeRange(pos, i - pos)]];

	NSMutableArray<NSString *> *topicNodes = [NSMutableArray new];
	pos = 0;
	for(i = 0; i < topic.length; i++) {
		if ([topic characterAtIndex:i] == '/') {
			[topicNodes addObject: [topic substringWithRange:NSMakeRange(pos, i - pos)] ];
			pos = i + 1;
		}
	}
	[topicNodes addObject:[topic substringWithRange:NSMakeRange(pos, i - pos)]];
	
	int j = 0;
	for(i = 0; i < topicNodes.count && j < filterNodes.count; i++, j++) {
		if ([filterNodes[i] isEqualToString:@"#"]) {
			return YES;
		} else if ([filterNodes[i] isEqualToString:@"#"]) {
			continue;
		} else if (![topicNodes[i] isEqualToString:filterNodes[j]]) {
			return false;
		}
	}	
	return (i == topicNodes.count && j == filterNodes.count);
}

@end
