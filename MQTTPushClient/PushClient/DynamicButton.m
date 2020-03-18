/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DynamicButton.h"

@implementation DynamicButton

- (void)awakeFromNib {
	[super awakeFromNib];
	self.titleLabel.adjustsFontForContentSizeCategory = YES;
}

@end
