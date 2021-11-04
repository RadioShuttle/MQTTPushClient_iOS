/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashJavaScriptOutput.h"

@interface DashJavaScriptOutput()

@property(copy) NSString *script;

@end

@implementation DashJavaScriptOutput

- (instancetype)initWithScript:(NSString *)outputScript {
	self = [super init];
	if (self) {
		NSURL *javaScriptColorURL = [[NSBundle mainBundle] URLForResource:@"javascript_color" withExtension:@"js"];
		NSString *javaScriptColor = [NSString stringWithContentsOfURL:javaScriptColorURL
															 encoding:NSUTF8StringEncoding error:NULL];
		NSURL *javaScriptUtilsURL = [[NSBundle mainBundle] URLForResource:@"utils" withExtension:@"js"];
		NSString *javaScriptUtils = [NSString stringWithContentsOfURL:javaScriptUtilsURL
															 encoding:NSUTF8StringEncoding error:NULL];

		self.context = [[JSContext alloc] init];
		
		self.script = [NSString stringWithFormat:@"%@\n%@\nvar setContent = function(input, msg, acc, view) {msg.text = input; %@ if (msg.raw instanceof ArrayBuffer) msg.rawHex = MQTT.buf2hex(msg.raw); return msg;}\n", javaScriptColor, javaScriptUtils, outputScript];
	}
	return self;
}

- (nullable NSDictionary *)formatOutput:(nullable NSString *)input msg:(nonnull NSDictionary *)msg acc:(nonnull NSDictionary *)acc
					  viewParameter:(nullable ViewParameter *)viewParameter
							  error:(NSError * _Nullable *_Nullable)error {
	
	if (viewParameter == nil) {
		viewParameter = [[ViewParameter alloc] init];
	}
	
	// Execute JavaScript on background queue:
	dispatch_group_t group = dispatch_group_create();
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	__block JSValue *value = nil;
	dispatch_group_async(group, background, ^{
		[self.context evaluateScript:self.script];
		JSValue *function = self.context[@"setContent"];
		value = [function callWithArguments:@[input, msg, acc, viewParameter]];
	});
	
	// Wait for script to finish (0.5 second timeout):
	dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
	long result = dispatch_group_wait(group, timeout);
	
	// Return error or result:
	if (self.context.exception) {
		if (error != NULL) {
			*error = [[NSError alloc] initWithDomain:@"JavaScriptError" code:28190
											userInfo:@{NSLocalizedDescriptionKey:self.context.exception.toString}];
		}
		return nil;
	} else if (result > 0) {
		if (error != NULL) {
			*error = [[NSError alloc] initWithDomain:@"JavaScriptError" code:28191
											userInfo:@{NSLocalizedDescriptionKey:@"timeout"}];
		}
		return nil;
	} else {
		return value.toDictionary;
	}
}

@end
