/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>

@interface JavaScriptFilter : NSObject

- (instancetype)initWithScript:(NSString *)filterScript;
- (nullable NSString *)filterMsg:(NSDictionary *)msg acc:(NSDictionary *)acc error:(NSError * _Nullable *)error;

@end
