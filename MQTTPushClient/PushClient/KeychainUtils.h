/*
 * $Id$
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface KeychainUtils : NSObject

+ (void)setPassword:(nullable NSString *)password forAccount:(NSString *)accountUuid;
+ (nullable NSString *)passwordForAccount:(NSString *)accountUuid;

+ (NSData *)deviceId;

@end

NS_ASSUME_NONNULL_END
