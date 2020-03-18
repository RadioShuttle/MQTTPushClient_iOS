/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDAccount;

NS_ASSUME_NONNULL_BEGIN

@interface CDMessage : NSManagedObject

@property (readonly) NSString *sectionIdentifier;

@end

NS_ASSUME_NONNULL_END

#import "CDMessage+CoreDataProperties.h"
