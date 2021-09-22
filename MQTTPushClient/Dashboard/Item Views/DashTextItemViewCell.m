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
	DashTextItem *textItem = (DashTextItem *)item;

	textItem.content = @"24 °";//TODO: remove
	
	/* set value text label */
	if (!textItem.content) {
		[self.textItemContainer.valueLabel setText:@""];
	} else {
		[self.textItemContainer.valueLabel setText:textItem.content];
	}
	
	/* text color */
	uint64_t color;
	if (textItem.textcolor == DASH_COLOR_OS_DEFAULT) {
		UIColor *defaultLabelColor = [UILabel new].textColor;
		[self.textItemContainer.valueLabel setTextColor:defaultLabelColor];
	} else {
		[self.textItemContainer.valueLabel setTextColor:UIColorFromRGB(textItem.textcolor)];
	}
	
	/* font size (TODO: consider moving to utility class */
	// UILabel * tmp = [UILabel new]; CGFloat labelFontSize = [tmp.font pointSize];
	CGFloat labelFontSize = 17.0f;
	int dashFontSize = item.textsize; // 0 - default, 1 small, 2 medium, 3 large
	if (dashFontSize == 0) { // use system default?
		dashFontSize = 2; // then use medium
	}
	if (dashFontSize == 1) {
		labelFontSize -= 2;
	} else if (dashFontSize == 3) {
		labelFontSize += 2;
	}
	self.textItemContainer.valueLabel.font = [self.textItemContainer.valueLabel.font fontWithSize:labelFontSize];	
	
	/* background color */
	if (item.background == DASH_COLOR_OS_DEFAULT) {
		color = DASH_DEFAULT_CELL_COLOR; //TODO: dark mode use color from asset
	} else {
		color = item.background;
	}	
	[self.textItemContainer setBackgroundColor:UIColorFromRGB(color)];
	
	/* background image (TODO: image caching) */
	UIImage *backgroundImage = [DashUtils loadImageResource:item.background_uri userDataDir:context.account.cacheURL];
	[self.textItemContainer.backgroundImageView setImage:backgroundImage];

	/* label */
	[self.textItemLabel setText:item.label];

}


@end
