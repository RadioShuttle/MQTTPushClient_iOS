/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Topic.h"
#import "NSDictionary+HelSafeAccessors.h"

static NSString *kPrefkeyTopicName = @"name";
static NSString *kPrefkeyTopicType = @"type";
static NSString *kPrefkeyTopicScript = @"script";

@implementation Topic

+ (nullable instancetype)topicFromUserDefaultsDict:(NSDictionary *)dict {
	NSString *name = [dict helStringForKey:kPrefkeyTopicName];
	NSNumber *type = [dict helNumberForKey:kPrefkeyTopicType];
	NSString *script = [dict helStringForKey:kPrefkeyTopicScript];
	if (name.length > 0) {
		Topic *topic = [[Topic alloc] init];
		topic.name = name;
		topic.type = type.intValue;
		topic.filterScript = script ? script : @"";
		return topic;
	} else {
		return nil;
	}
}

- (NSDictionary *)userDefaultsDict {
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								 self.name, kPrefkeyTopicName,
								 @(self.type), kPrefkeyTopicType,
								 self.filterScript, kPrefkeyTopicScript,
								 nil];
	return dict;
}

@end
