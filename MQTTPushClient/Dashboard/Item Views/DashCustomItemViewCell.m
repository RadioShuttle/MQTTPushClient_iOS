/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCustomItemViewCell.h"

@implementation DashCustomItemViewCell

-(void)onBind:(DashItem *)item context:(Dashboard *)context {
	[super onBind:item context:context];
	
	if (self.webviewContainer.userInteractionEnabled) {
		self.webviewContainer.userInteractionEnabled = NO;
	};
	[self.webviewContainer onBind:item context:context];

	/* label */
	[self.customItemLabel setText:item.label];
	
	/* error info */
	//TODO:
	[self showErrorInfo:NO error2:NO];

}
@end
