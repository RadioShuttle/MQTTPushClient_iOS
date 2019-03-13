/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <JavaScriptCore/JavaScriptCore.h>
#import "JavaScriptFilter.h"

@interface JavaScriptFilter()

@property(copy) NSString *script;

@end

@implementation JavaScriptFilter

- (instancetype)initWithScript:(NSString *)filterScript {
	self = [super init];
	if (self) {
		_script = [NSString stringWithFormat:@"var filter = function(msg, acc) {\nvar content = msg.text\n%@\nreturn content;\n}\n", filterScript];
	}
	return self;
}

- (nullable NSString *)filterMsg:(NSDictionary *)msg acc:(NSDictionary *)acc error:(NSError * _Nullable *)error {

	// Execute JavaScript on background queue:
	dispatch_group_t group = dispatch_group_create();
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	JSContext *context = [[JSContext alloc] init];
	__block JSValue *value = nil;
	dispatch_group_async(group, background, ^{
		[context evaluateScript:self.script];
		JSValue *function = [context objectForKeyedSubscript:@"filter"];
		value = [function callWithArguments:@[msg, acc]];
	});

	// Wait for script to finish (0.5 second timeout):
	dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
	long result = dispatch_group_wait(group, timeout);

	// Return error or result:
	if (context.exception) {
		*error = [[NSError alloc] initWithDomain:@"JavaScriptError" code:28190
										userInfo:@{NSLocalizedDescriptionKey:context.exception.toString}];
		return nil;
	} else if (result > 0) {
		*error = [[NSError alloc] initWithDomain:@"JavaScriptError" code:28191
										userInfo:@{NSLocalizedDescriptionKey:@"timeout"}];
		return nil;
	} else {
		return value.toString;
	}
}

@end
