/*
 * $Id$
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
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
