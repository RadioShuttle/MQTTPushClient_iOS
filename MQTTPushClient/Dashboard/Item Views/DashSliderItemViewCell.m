/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashSliderItemViewCell.h"

@implementation DashSliderItemViewCell

- (void)onBind:(DashItem *)item context:(Dashboard *)context {
	[super onBind:item context:context];

	[self.itemContainer onBind:item context:context];
	
	/* label */
	[self.itemLabel setText:item.label];
	
	/* error info */
	//TODO:
	[self showErrorInfo:NO error2:NO];

}

@end
