/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TokenManager : NSObject

+ (instancetype)sharedTokenManager;
- (void)deleteTokenFor:(nullable NSString *)senderID;
- (void)resume;

@end

NS_ASSUME_NONNULL_END
