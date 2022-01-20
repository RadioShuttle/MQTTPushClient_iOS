/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashOptionItemViewCell.h"

@implementation DashOptionItemViewCell

- (void)onBind:(DashItem *)item context:(Dashboard *)context selected:(BOOL)selected {
	[super onBind:item context:context label:self.itemLabel selected:selected];
	
	[self.itemContainer onBind:item context:context container:self];
}
@end
