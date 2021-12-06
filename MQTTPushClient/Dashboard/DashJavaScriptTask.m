/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashJavaScriptTask.h"
#import "DashItem.h"
#import "JavaScriptFilter.h"
#import "DashJavaScriptOutput.h"
#import "DashViewParameter.h"
#import "Utils.h"
#import "NSString+HELUtils.h"
#import "NSDictionary+HelSafeAccessors.h"

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
		if (requestData) {
			self.data = [requestData mutableCopy];
		} else {
			self.data = [NSMutableDictionary new];
		}
		[self.data setObject:[NSNumber numberWithUnsignedLongLong:self.version] forKey:@"version"];
		[self.data setObject:[NSNumber numberWithUnsignedLong:item.id_] forKey:@"id"];
		if (self.output) {
			[self.data setObject:[NSNumber numberWithBool:output] forKey:@"output"];
		}
		if (msgOrPublishData) {
			[self.data setObject:msgOrPublishData forKey:@"message"];
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
	[self performSelectorOnMainThread:@selector(postJSTaskFinishedNotification:) withObject:self.data waitUntilDone:YES];
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
		[self.data setObject:result forKey:@"filterMsgResult"];
	}
	
	if (error) {
		/* on error set message content */
		[self.data setObject:error forKey:@"error"];
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
	NSError *error = nil;
	DashJavaScriptOutput *outputScript = [[DashJavaScriptOutput alloc] initWithScript:self.item.script_p];
	NSString *input = [self.message contentToStr];
	NSObject *raw = [NSNull null];	
	NSDictionary *arg1 = @{@"raw":raw, @"text":[self.message contentToStr], @"topic":self.message.topic, @"receivedDate":self.message.timestamp};
	NSDictionary *arg2 = @{@"user":self.account.mqttUser, @"mqttServer":self.account.mqttHost, @"pushServer":self.account.host};
	
	DashViewParameter *viewParameter = [DashViewParameter viewParameterWithItem:self.item context:outputScript.context account:self.account];
	
	NSDictionary *result = [outputScript formatOutput:input msg:arg1 acc:arg2 viewParameter:viewParameter error:&error];

	if (error) {
		[self.data setObject:error forKey:@"error"];
		self.item.error2 = [Utils isEmpty:[error localizedDescription]] ? @"n/a" : [error localizedDescription];
		NSLog(@"Javascript error: %@", self.item.error2);
	} else {
		self.item.error2 = nil;
		
		DashMessage *msg = [self.data objectForKey:@"message"];
		/* update the message's content with the result from javascript */
		if (msg) {
			NSData *resultData = [[result helStringForKey:@"rawHex"] dataFromHex]; // raw data has precedence
			if (!resultData) {
				resultData = [[result helStringForKey:@"text"] dataUsingEncoding:NSUTF8StringEncoding];
				if (!resultData) {
					resultData = [NSData data];
				}
			}
			msg.content = resultData;
		}
	}
}

@end
