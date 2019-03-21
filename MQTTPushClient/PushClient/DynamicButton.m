/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "DynamicButton.h"

@implementation DynamicButton

- (void)awakeFromNib {
	[super awakeFromNib];
	self.titleLabel.adjustsFontForContentSizeCategory = YES;
}

@end
