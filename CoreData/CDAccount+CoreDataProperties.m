/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "CDAccount+CoreDataProperties.h"

@implementation CDAccount (CoreDataProperties)

+ (NSFetchRequest<CDAccount *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"CDAccount"];
}

@dynamic lastUpdate;
@dynamic lastRead;
@dynamic syncTimestamp;
@dynamic syncMessageID;
@dynamic messages;

@end
