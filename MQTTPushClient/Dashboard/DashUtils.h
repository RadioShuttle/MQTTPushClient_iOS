/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>
@import UIKit;

@interface DashUtils : NSObject

+(BOOL) isUserResource:(NSString *)uri;
+(BOOL) isImportedResource:(NSString *)uri;
+(BOOL) isInternalResource:(NSString *)uri;

+(NSString *)getURIPath:(NSString *)uri;

+(NSURL *)getUserFilesDir:(NSURL *)path;
+(NSURL *)getImportedFilesDir:(NSURL *)path;
+(NSURL *)appendStringToURL:(NSURL *)url str:(NSString *)str;
+(BOOL)fileExists:(NSURL *)fileUrl;

+(NSString *)getResourceURIFromResourceName:(NSString *) resourceName userDataDir:(NSURL *)userDataDir;

+(UIImage *)loadImageResource:(NSString *)uri userDataDir:(NSURL *)userDataDir;

/* returns font size for given itemSize: 0 - default, 1 small, 2 medium, 3 large */
+(CGFloat)getLabelFontSize:(int)itemSize;

+(UIImage *)imageWithColor:(UIColor *)color;

+(NSString *)buildResourceURI:(NSString *)type resourceName:(NSString *)name;

/* compare dash color (5 byte color: flag, a, r, g, b) */
+(BOOL)cmpColor:(int64_t)c color:(int64_t)c2;

@end
