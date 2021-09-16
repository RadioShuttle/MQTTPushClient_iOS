/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashUtils.h"
#import "DashConsts.h"
#import "Utils.h"

@implementation DashUtils

+(BOOL) isUserResource:(NSString *)uri {
	return ![Utils isEmpty:uri] && [[uri lowercaseString] hasPrefix:@"res://user/"];
}

+(NSString *)getURIPath:(NSString *)uri {
	NSString *uriPath = nil;
	if (uri) {
		NSURL *u = [NSURL URLWithString:uri];
		uriPath = [u path];
		if ([uriPath hasPrefix:@"/"]) {
			uriPath = [uriPath substringFromIndex:1];
		}
	}
	return uriPath;
}

+(NSURL *)getUserFilesDir:(NSURL *)path {
	NSURL* dir = nil;
	if (path) {
		dir = [path URLByAppendingPathComponent:LOCAL_USER_FILES_DIR isDirectory:YES];
		
		NSFileManager *fm = [NSFileManager defaultManager];
		if (![fm fileExistsAtPath:[dir path]]) {
			if (![fm createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil]) {
				NSLog(@"Error: Could not create user images dir!");
			}
		}
	}
	return dir;
}

+(NSURL *)appendStringToURL:(NSURL *)url str:(NSString *)str {
	return [url URLByAppendingPathComponent:str isDirectory:NO];
}

+(BOOL)fileExists:(NSURL *)fileUrl {
	return [[NSFileManager defaultManager] fileExistsAtPath:[fileUrl path]];
}

@end
