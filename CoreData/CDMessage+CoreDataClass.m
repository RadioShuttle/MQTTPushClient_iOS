/*
 * $Id$
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "CDMessage+CoreDataClass.h"

@interface CDMessage ()
@property (nonatomic) NSDate *primitiveTimestamp;
@property (nonatomic) NSString *primitiveSectionIdentifier;
@end

@implementation CDMessage

@dynamic primitiveTimestamp, primitiveSectionIdentifier;

- (NSString *)sectionIdentifier {
	// Create and cache the section identifier on demand.
	
	[self willAccessValueForKey:@"sectionIdentifier"];
	NSString *tmp = [self primitiveSectionIdentifier];
	[self didAccessValueForKey:@"sectionIdentifier"];
	
	if (tmp == nil) {
		/*
		 * Sections are organized by day, month and year.
		 * Create the section identifier as a string "YYYYMMDD".
		 */
		NSCalendar *calendar = [NSCalendar currentCalendar];
		NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:self.timestamp];
		tmp = [NSString stringWithFormat:@"%04ld%02ld%02ld", (long)[components year],
			   (long)[components month], (long)components.day];
		[self setPrimitiveSectionIdentifier:tmp];
	}
	return tmp;
}

#pragma mark - Time stamp setter

- (void)setTimestamp:(NSDate *)newDate {
	// If the time stamp changes, the section identifier becomes invalid.
	[self willChangeValueForKey:@"timestamp"];
	[self setPrimitiveTimestamp:newDate];
	[self didChangeValueForKey:@"timestamp"];
	[self setPrimitiveSectionIdentifier:nil];
}

#pragma mark - Key path dependencies

+ (NSSet *)keyPathsForValuesAffectingSectionIdentifier {
	// If the value of timeStamp changes, the section identifier may change as well.
	return [NSSet setWithObject:@"timestamp"];
}
@end
