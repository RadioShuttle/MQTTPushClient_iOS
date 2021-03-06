/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "CDAccount+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CDAccount (CoreDataProperties)

+ (NSFetchRequest<CDAccount *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDate *lastUpdate;
@property (nullable, nonatomic, copy) NSDate *lastRead;
@property (nullable, nonatomic, copy) NSDate *syncTimestamp;
@property (nonatomic) int32_t syncMessageID;
@property (nullable, nonatomic, retain) NSSet<CDMessage *> *messages;

@end

@interface CDAccount (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(CDMessage *)value;
- (void)removeMessagesObject:(CDMessage *)value;
- (void)addMessages:(NSSet<CDMessage *> *)values;
- (void)removeMessages:(NSSet<CDMessage *> *)values;

@end

NS_ASSUME_NONNULL_END
