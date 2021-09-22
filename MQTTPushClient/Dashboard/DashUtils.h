/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>
@import UIKit;

@interface DashUtils : NSObject

+(BOOL) isUserResource:(NSString *)uri;
+(BOOL) isInternalResource:(NSString *)uri;

+(NSString *)getURIPath:(NSString *)uri;

+(NSURL *)getUserFilesDir:(NSURL *)path;
+(NSURL *)appendStringToURL:(NSURL *)url str:(NSString *)str;
+(BOOL)fileExists:(NSURL *)fileUrl;

+(UIImage *)loadImageResource:(NSString *)uri userDataDir:(NSURL *)userDataDir;

@end
