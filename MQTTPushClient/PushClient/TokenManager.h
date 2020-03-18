/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TokenManager : NSObject

+ (instancetype)sharedTokenManager;
- (void)deleteTokenFor:(nullable NSString *)senderID;
- (void)resume;

@end

NS_ASSUME_NONNULL_END
