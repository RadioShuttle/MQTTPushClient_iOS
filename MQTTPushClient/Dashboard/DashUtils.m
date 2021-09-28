/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashUtils.h"
#import "DashConsts.h"
#import "Utils.h"
#import "NSString+HELUtils.h"

@implementation DashUtils

+(BOOL) isUserResource:(NSString *)uri {
	return ![Utils isEmpty:uri] && [[uri lowercaseString] hasPrefix:@"res://user/"];
}

+(BOOL) isInternalResource:(NSString *)uri {
	return ![Utils isEmpty:uri] && [[uri lowercaseString] hasPrefix:@"res://internal/"];
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

+(UIImage *)loadImageResource:(NSString *)uri userDataDir:(NSURL *)userDataDir {
	UIImage *img;
	if (![Utils isEmpty:uri]) {
		NSString *resourceName = [DashUtils getURIPath:uri];
		if ([self isInternalResource:uri]) {
			/*
			img = [[UIImage imageNamed:resourceName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			 */
			img = [UIImage imageNamed:resourceName] ;
		}
		else if ([self isUserResource:uri]) {
			NSString *internalFilename = [NSString stringWithFormat:@"%@.%@", [resourceName enquoteHelios], DASH512_PNG];
			NSURL *localDir = [DashUtils getUserFilesDir:userDataDir];
			NSURL *fileURL = [DashUtils appendStringToURL:localDir str:internalFilename];
			img = [UIImage imageWithContentsOfFile:[fileURL path]];
		}
	}
	return img;
}

+(UIImageView *)createImageView:(UIView *)targetView {
	UIImageView * view =  [[UIImageView alloc] init];
	view = [[UIImageView alloc] init];
	view.contentMode = UIViewContentModeScaleAspectFit;
	view.translatesAutoresizingMaskIntoConstraints = NO;
	[targetView addSubview:view];
	[view.leadingAnchor constraintEqualToAnchor:targetView.leadingAnchor constant:0.0].active = YES;
	[view.trailingAnchor constraintEqualToAnchor:targetView.trailingAnchor constant:0.0].active = YES;
	[view.topAnchor constraintEqualToAnchor:targetView.topAnchor constant:0.0].active = YES;
	[view.bottomAnchor constraintEqualToAnchor:targetView.bottomAnchor constant:0.0].active = YES;
	return view;
}

@end
