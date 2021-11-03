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

@interface DashJavaScriptTask()
@property BOOL output;
@end

@implementation DashJavaScriptTask

-(instancetype)initWithItem:(DashItem *)item message:(DashMessage *)msg version:(uint64_t)version account:(Account *)account {
	return [self initWithItem:item message:msg version:version account:account requestData:nil output:NO];
}

-(instancetype)initWithItem:(DashItem *)item publishData:(DashMessage *)publishData version:(uint64_t)version account:(Account *)account requestData:(NSDictionary *)requestData {
	return [self initWithItem:item message:publishData version:version account:account requestData:requestData output:YES];
}

-(instancetype)initWithItem:(DashItem *)item message:(DashMessage *)msgOrPublishData version:(uint64_t)version account:(Account *)account requestData:(NSDictionary *)requestData  output:(BOOL) output{

	if (self = [super init]) {
		self.timestamp = [NSDate new];
		self.item = item;
		self.message = msgOrPublishData;
		self.version = version;
		self.account = account;
		self.output = output;
		
		self.data = [NSMutableDictionary new];
		[self.data setObject:[NSNumber numberWithUnsignedLongLong:self.version] forKey:@"version"];
		[self.data setObject:[NSNumber numberWithUnsignedLong:item.id_] forKey:@"id"];
		if (self.output) {
			[self.data setObject:requestData forKey:@"request_data"];
		}
	}
	return self;
}


-(void)execute {
	if (self.output) {
		[self executeOutputScript];
	} else {
		[self executeFilterScript];
	}
	
	/* notify obervers */
	[self performSelectorOnMainThread:@selector(postJSTaskFinishedNotification:) withObject:self.data waitUntilDone:NO];
}

-(void)executeFilterScript {
	
	NSError *error = nil;
	JavaScriptFilter *filter = [[JavaScriptFilter alloc] initWithScript:self.item.script_f];
	NSObject *raw = [filter arrayBufferFromData:self.message.content];
	NSDictionary *arg1 = @{@"raw":raw, @"text":[self.message contentToStr], @"topic":self.message.topic, @"receivedDate":self.message.timestamp};
	NSDictionary *arg2 = @{@"user":self.account.mqttUser, @"mqttServer":self.account.mqttHost, @"pushServer":self.account.host};
	
	DashViewParameter *viewParameter = [DashViewParameter viewParameterWithItem:self.item context:filter.context account:self.account];
	
	NSString *result = [filter filterMsg:arg1 acc:arg2 viewParameter:viewParameter error:&error];
	if (result) {
		self.item.content = result;
		self.item.lastMsgTimestamp = self.message.timestamp;
	}
	
	if (error) {
		/* on error set message content */
		self.item.content = [self.message contentToStr];
		self.item.error1 = [Utils isEmpty:[error localizedDescription]] ? @"n/a" : [error localizedDescription];
		NSLog(@"Javasciprt error: %@", self.item.error1);
	} else {
		self.item.error1 = nil;
	}
}

- (void)postJSTaskFinishedNotification:(NSDictionary *)userInfo {
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DashJavaScriptTaskNotification" object:self userInfo:userInfo];
}

-(void)executeOutputScript {
	NSLog(@"executing output script ...");
	//TODO: implement
	
}

@end
