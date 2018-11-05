/*
 * $Id$
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "CDMessage+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CDMessage (CoreDataProperties)

+ (NSFetchRequest<CDMessage *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *messageID;
@property (nullable, nonatomic, copy) NSString *topic;
@property (nullable, nonatomic, copy) NSString *content;
@property (nullable, nonatomic, copy) NSDate *timestamp;
@property (nullable, nonatomic, retain) CDAccount *account;
@property (nullable, nonatomic, copy) NSString *sectionIdentifier; // transient

@end

NS_ASSUME_NONNULL_END
