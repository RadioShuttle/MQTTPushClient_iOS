/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "CDMessage+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CDMessage (CoreDataProperties)

+ (NSFetchRequest<CDMessage *> *)fetchRequest;

@property (nonatomic) int32_t messageID;
@property (nullable, nonatomic, copy) NSString *topic;
@property (nullable, nonatomic, copy) NSData *content;
@property (nullable, nonatomic, copy) NSDate *timestamp;
@property (nullable, nonatomic, retain) CDAccount *account;

@end

NS_ASSUME_NONNULL_END
