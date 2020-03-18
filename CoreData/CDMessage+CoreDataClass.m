/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "CDMessage+CoreDataClass.h"

@implementation CDMessage

- (NSString *)sectionIdentifier {
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:self.timestamp];
	NSString *tmp = [NSString stringWithFormat:@"%04ld%02ld%02ld", (long)[components year],
		   (long)[components month], (long)components.day];
	return tmp;
}

@end
