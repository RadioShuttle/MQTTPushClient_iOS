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

@dynamic messageID;
@dynamic topic;
@dynamic content;
@dynamic timestamp;
@dynamic account;

@end
