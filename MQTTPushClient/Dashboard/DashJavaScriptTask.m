/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashJavaScriptTask.h"
#import "DashItem.h"
#import "JavaScriptFilter.h"
#import "DashViewParameter.h"
#import "Utils.h"

@implementation DashJavaScriptTask

-(instancetype)initWithItem:(DashItem *)item message:(DashMessage *)msg version:(uint64_t)version account:(Account *)account {
	if (self = [super init]) {
		self.timestamp = [NSDate new];
		self.item = item;
		self.message = msg;
		self.version = version;
		self.account = account;
		
		self.data = [NSMutableDictionary new];
		[self.data setObject:[NSNumber numberWithUnsignedLongLong:self.version] forKey:@"version"];
		[self.data setObject:[NSNumber numberWithUnsignedLong:item.id_] forKey:@"id"];

	}
	return self;
}

-(void)execute {
	
	NSError *error = nil;
	JavaScriptFilter *filter = [[JavaScriptFilter alloc] initWithScript:self.item.script_f];
	NSObject *raw = [filter arrayBufferFromData:self.message.content];
	NSDictionary *arg1 = @{@"raw":raw, @"text":[Message msgFromData:self.message.content], @"topic":self.message.topic, @"receivedDate":self.message.timestamp};
	NSDictionary *arg2 = @{@"user":self.account.mqttUser, @"mqttServer":self.account.mqttHost, @"pushServer":self.account.host};
	
	DashViewParameter *viewParameter = [DashViewParameter viewParameterWithItem:self.item context:filter.context account:self.account];
	
	NSString *result = [filter filterMsg:arg1 acc:arg2 viewParameter:viewParameter error:&error];
	if (result) {
		self.item.content = result;
	}
	
	if (error) {
		/* on error set message content */
		self.item.content = [DashMessage msgFromData:self.message.content];
		self.item.error1 = [Utils isEmpty:[error localizedDescription]] ? @"n/a" : [error localizedDescription];
		NSLog(@"Javasciprt error: %@", self.item.error1);
	} else {
		self.item.error1 = nil;
	}

	/* notify obervers */
	[self performSelectorOnMainThread:@selector(postJSTaskFinishedNotification:) withObject:self.data waitUntilDone:NO];
}

- (void)postJSTaskFinishedNotification:(NSDictionary *)userInfo {
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DashJavaScriptTaskNotification" object:self userInfo:userInfo];
}


@end
