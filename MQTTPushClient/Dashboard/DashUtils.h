/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DashUtils : NSObject

+(BOOL) isUserResource:(NSString *)uri;
+(NSString *)getURIPath:(NSString *)uri;

+(NSURL *)getUserFilesDir:(NSURL *)path;
+(NSURL *)appendStringToURL:(NSURL *)url str:(NSString *)str;
+(BOOL)fileExists:(NSURL *)fileUrl;

@end

NS_ASSUME_NONNULL_END
