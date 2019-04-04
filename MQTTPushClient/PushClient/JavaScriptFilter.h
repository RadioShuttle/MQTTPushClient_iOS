/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>

@interface JavaScriptFilter : NSObject

- (nonnull instancetype)initWithScript:(nonnull NSString *)filterScript;
- (nullable NSString *)filterMsg:(nonnull NSDictionary *)msg acc:(nonnull NSDictionary *)acc error:(NSError * _Nullable *_Nullable)error;
- (nonnull NSObject *)arrayBufferFromData:(nullable NSData *)data;

@end
