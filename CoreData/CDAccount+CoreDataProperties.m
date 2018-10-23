/*
 * $Id$
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "CDAccount+CoreDataProperties.h"

@implementation CDAccount (CoreDataProperties)

+ (NSFetchRequest<CDAccount *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"CDAccount"];
}

@dynamic last_update;
@dynamic messages;

@end
