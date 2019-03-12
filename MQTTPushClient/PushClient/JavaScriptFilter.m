/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <JavaScriptCore/JavaScriptCore.h>
#import "JavaScriptFilter.h"

@interface JavaScriptFilter()

@property NSString *script;

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
	__block NSString *text = @"";
	__block NSError *scriptError = nil;
	dispatch_group_t group = dispatch_group_create();
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_group_async(group, background, ^{
		__block BOOL exception = NO;
		JSContext *context = [[JSContext alloc] init];
		[context setExceptionHandler:^(JSContext *context, JSValue *value) {
			text = value.toString;
			exception = YES;
		}];
		[context evaluateScript:self.script];
		JSValue *function = [context objectForKeyedSubscript:@"filter"];
		JSValue *value = [function callWithArguments:@[msg, acc]];
		if (exception)
			scriptError = [[NSError alloc] initWithDomain:@"JavaScriptError" code:28190 userInfo:@{NSLocalizedDescriptionKey:text}];
		else
			text = value.toString;
	});
	uint64_t timeout = dispatch_time( DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC); // in nano seconds
	long result = dispatch_group_wait(group, timeout);
	if (result > 0)
		scriptError = [[NSError alloc] initWithDomain:@"JavaScriptError" code:28191 userInfo:@{NSLocalizedDescriptionKey:@"timeout"}];
	*error = scriptError;
	return text;
}

@end
