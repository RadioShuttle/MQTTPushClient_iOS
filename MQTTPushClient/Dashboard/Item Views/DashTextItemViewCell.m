/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashTextItemViewCell.h"
#import "DashTextItem.h"
#import "DashUtils.h"
#import "DashConsts.h"
#import "Utils.h"
#import "Dashboard.h"
#import "NSString+HELUtils.h"

@implementation DashTextItemViewCell

-(void)onBind:(DashItem *)item context:(Dashboard *)context {
	[super onBind:item context:context];
	
	[self.textItemContainer onBind:item context:context];

	/* label */
	[self.textItemLabel setText:item.label];
}

@end
