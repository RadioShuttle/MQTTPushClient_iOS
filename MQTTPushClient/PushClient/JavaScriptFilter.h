/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>

@interface JavaScriptFilter : NSObject

- (nonnull instancetype)initWithScript:(nonnull NSString *)filterScript;
- (nullable NSString *)filterMsg:(nonnull NSDictionary *)msg acc:(nonnull NSDictionary *)acc error:(NSError * _Nullable *_Nullable)error;
- (nonnull NSObject *)arrayBufferFromData:(nullable NSData *)data;

@end
