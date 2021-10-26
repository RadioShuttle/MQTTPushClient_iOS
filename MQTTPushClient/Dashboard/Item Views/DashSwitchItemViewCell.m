/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashSwitchItemViewCell.h"
#import "DashSwitchItem.h"
#import "DashUtils.h"
#import "DashConsts.h"

@implementation DashSwitchItemViewCell

-(void)onBind:(DashItem *)item context:(Dashboard *)context {
	[super onBind:item context:context label:self.itemLabel];
	
	DashSwitchItem *switchItem = (DashSwitchItem *) item;
	
	self.switchItemContainer.button.userInteractionEnabled = NO;
	[self.switchItemContainer onBind:switchItem context:context];
}

@end
