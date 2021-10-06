/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashJavaScriptTask.h"
#import "DashItem.h"

@implementation DashJavaScriptTask

-(instancetype)initWithItem:(DashItem *)item message:(DashMessage *)msg version:(uint64_t) dashVersion {
	if (self = [super init]) {
		self.timestamp = [NSDate new];
		//TODO: ...
		self.data = [NSMutableDictionary new];
		[self.data setObject:[NSNumber numberWithUnsignedLongLong:dashVersion] forKey:@"version"];
		[self.data setObject:[NSNumber numberWithUnsignedLong:item.id_] forKey:@"id"];

	}
	return self;
}

-(void)execute {
	//TODO: ...
	NSData* testdata = [(@"24") dataUsingEncoding:NSUTF8StringEncoding];
	[self.data setObject:testdata forKey:@"result"];

	/* notify obervers */
	[self performSelectorOnMainThread:@selector(postJSTaskFinishedNotification:) withObject:self.data waitUntilDone:NO];
}

- (void)postJSTaskFinishedNotification:(NSDictionary *)userInfo {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DashJavaScriptTaskNotification" object:self userInfo:userInfo];
}


@end
