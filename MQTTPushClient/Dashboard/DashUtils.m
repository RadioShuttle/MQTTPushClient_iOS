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

+(UIImage *)loadImageResource:(NSString *)uri userDataDir:(NSURL *)userDataDir renderingModeAlwaysTemplate:(BOOL)renderingModeAlwaysTemplate {

	UIImage *img;
	if (![Utils isEmpty:uri]) {
		NSString *resourceName = [DashUtils getURIPath:uri];
		if ([self isInternalResource:uri]) {
			if (renderingModeAlwaysTemplate) {
				img = [[UIImage imageNamed:resourceName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			} else {
				img = [UIImage imageNamed:resourceName];
			}
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

+(UIImage *)loadImageResource:(NSString *)uri userDataDir:(NSURL *)userDataDir {
	return [self loadImageResource:uri userDataDir:userDataDir renderingModeAlwaysTemplate:YES];
}

+(NSString *)getResourceURIFromResourceName:(NSString *) resourceName userDataDir:(NSURL *)userDataDir {
	NSString *uri = nil;
	
	if ([resourceName hasPrefix:@"/"]) {
		resourceName = [resourceName substringFromIndex:1];
	}
	
	BOOL checkUserRes = NO;
	NSString *path = [resourceName lowercaseString];
	if ([path hasPrefix:@"int/"]) {
		resourceName = [resourceName substringFromIndex:4];
	} else {
		if ([path hasPrefix:@"user/"]) {
			resourceName = [resourceName substringFromIndex:5];
		}
		checkUserRes = YES;
	}
	if (checkUserRes) {
		NSString *internalFilename = [NSString stringWithFormat:@"%@.%@", [resourceName enquoteHelios], DASH512_PNG];
		NSURL *localDir = [DashUtils getUserFilesDir:userDataDir];
		NSURL *fileURL = [DashUtils appendStringToURL:localDir str:internalFilename];
		if ([DashUtils fileExists:fileURL]) {
			NSString *pc = [resourceName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
			uri = [NSString stringWithFormat:@"res://user/%@", pc];
		}
	}
	if ([Utils isEmpty:uri]) {
		NSURL *svgImageURL = [[NSBundle mainBundle] URLForResource:resourceName withExtension:@"svg"];
		if ([DashUtils fileExists:svgImageURL]) {
			NSString *pc = [resourceName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
			uri = [NSString stringWithFormat:@"res://internal/%@", pc];
		}
	}
	return uri;
}

+(CGFloat)getLabelFontSize:(int)itemSize {
	CGFloat labelFontSize = 17.0f;
	int dashFontSize = itemSize; // 0 - default, 1 small, 2 medium, 3 large
	if (dashFontSize == 0) { // use system default?
		dashFontSize = 2; // then use medium
	}
	if (dashFontSize == 1) {
		labelFontSize -= 2;
	} else if (dashFontSize == 3) {
		labelFontSize += 2;
	}
	return labelFontSize;
}
@end
