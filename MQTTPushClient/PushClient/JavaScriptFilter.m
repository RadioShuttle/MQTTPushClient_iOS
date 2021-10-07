/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "JavaScriptFilter.h"

@interface JavaScriptFilter()

@property(copy) NSString *script;

@end

@implementation JavaScriptFilter

- (instancetype)initWithScript:(NSString *)filterScript {
	self = [super init];
	if (self) {
		NSURL *javaScriptColorURL = [[NSBundle mainBundle] URLForResource:@"javascript_color" withExtension:@"js"];
		NSString *javaScriptColor = [NSString stringWithContentsOfURL:javaScriptColorURL
														encoding:NSUTF8StringEncoding error:NULL];

		_context = [[JSContext alloc] init];
		_script = [NSString stringWithFormat:@"var filterMsg = function(msg, acc, view) {\n%@\nvar content = msg.text\n%@\nreturn content;\n}\n", javaScriptColor, filterScript];
	}
	return self;
}

- (nullable NSString *)filterMsg:(NSDictionary *)msg acc:(NSDictionary *)acc
				   viewParameter:(ViewParameter *)viewParameter
						   error:(NSError * _Nullable *)error {
	
	if (viewParameter == nil) {
		viewParameter = [[ViewParameter alloc] init];
	}

	// Execute JavaScript on background queue:
	dispatch_group_t group = dispatch_group_create();
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	__block JSValue *value = nil;
	dispatch_group_async(group, background, ^{
		[self.context evaluateScript:self.script];
		JSValue *function = self.context[@"filterMsg"];
		value = [function callWithArguments:@[msg, acc, viewParameter]];
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
		return value.toString;
	}
}

// Deallocator function for JSObjectMakeArrayBufferWithBytesNoCopy()
void arrayBytesDeallocator(void *bytes, void *context) {
	free(bytes);
}

// Create an JavaScript ArrayBuffer from the given data.
- (NSObject *)arrayBufferFromData:(NSData *)data {
	JSValueRef  except;
	void *bytes = malloc(data.length);
	memcpy(bytes, data.bytes, data.length);
	JSValueRef val = JSObjectMakeArrayBufferWithBytesNoCopy([self.context JSGlobalContextRef],
																  bytes, data.length,
																  arrayBytesDeallocator, nil, &except);
	return [JSValue valueWithJSValueRef:val inContext:self.context];
}

@end
