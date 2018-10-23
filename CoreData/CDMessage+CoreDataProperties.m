/*
 * $Id$
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "CDMessage+CoreDataProperties.h"

@implementation CDMessage (CoreDataProperties)

+ (NSFetchRequest<CDMessage *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"CDMessage"];
}

@dynamic message_id;
@dynamic topic;
@dynamic text;
@dynamic timestamp;
@dynamic account;

@end
