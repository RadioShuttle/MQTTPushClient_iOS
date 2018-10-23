/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import Foundation;
#import "Account.h"

NS_ASSUME_NONNULL_BEGIN

@interface AccountList : NSObject <NSFastEnumeration>

+ (instancetype)sharedAccountList;

@property (nonatomic, readonly) NSUInteger count;
- (Account *)objectAtIndexedSubscript:(NSUInteger)index;
- (void)addAccount:(Account *)account;
- (void)removeAccountAtIndex:(NSUInteger) index;
- (void)moveAccountAtIndex:(NSUInteger) fromIndex toIndex:(NSUInteger) toIndex;

- (void)save;

@end

NS_ASSUME_NONNULL_END
