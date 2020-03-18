/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
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
