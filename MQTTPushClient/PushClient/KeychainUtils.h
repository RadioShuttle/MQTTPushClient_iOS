/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface KeychainUtils : NSObject

+ (void)setPassword:(nullable NSString *)password forAccount:(NSString *)accountUuid;
+ (nullable NSString *)passwordForAccount:(NSString *)accountUuid;

@end

NS_ASSUME_NONNULL_END
