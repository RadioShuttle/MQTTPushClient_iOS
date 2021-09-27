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
	[super onBind:item context:context];
	
	DashSwitchItem *switchItem = (DashSwitchItem *) item;
	
	self.switchItemContainer.button.userInteractionEnabled = NO;
	
	int64_t buttonTintColor;
	NSString *buttonTitle;
	NSString *imageURI;
	if ([switchItem isOnState]) {
		buttonTitle = switchItem.val;
		buttonTintColor = switchItem.color;
		imageURI = switchItem.uri;
	} else {
		buttonTitle = switchItem.valOff;
		buttonTintColor = switchItem.colorOff;
		imageURI = switchItem.uriOff;
	}
	if (buttonTintColor == DASH_COLOR_CLEAR) {
		[self.switchItemContainer.button setTintColor:nil];
	} else if (buttonTintColor == DASH_COLOR_OS_DEFAULT) {
		UIColor *textColor = [UILabel new].textColor;
		[self.switchItemContainer.button setTintColor:textColor];
	} else {
		[self.switchItemContainer.button setTintColor:UIColorFromRGB(buttonTintColor)];
	}

	UIImage *image;
	if (imageURI.length > 0) {
		//TODO: caching
		image = [DashUtils loadImageResource:imageURI userDataDir:context.account.cacheURL];
	}
	if (image) {
		self.switchItemContainer.button.imageView.contentMode = UIViewContentModeScaleAspectFit;
		self.switchItemContainer.button.imageEdgeInsets = UIEdgeInsetsMake(16,16,16,16);
		self.switchItemContainer.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
		[self.switchItemContainer.button setImage:image forState:UIControlStateNormal];
		self.switchItemContainer.button.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
		
		[self.switchItemContainer.button setTitle:nil forState:UIControlStateNormal];
	} else {
		if (buttonTintColor == DASH_COLOR_CLEAR) { // no image visibile? use label color for text button
			UIColor *textColor = [UILabel new].textColor;
			[self.switchItemContainer.button setTintColor:textColor];
		}
		[self.switchItemContainer.button setImage:nil forState:UIControlStateNormal];
		[self.switchItemContainer.button setTitle:buttonTitle forState:UIControlStateNormal];
	}


	/* background color */
	uint64_t color;

	if (item.background == DASH_COLOR_OS_DEFAULT) {
		color = DASH_DEFAULT_CELL_COLOR; //TODO: dark mode use color from asset
	} else {
		color = item.background;
	}
	[self.switchItemContainer setBackgroundColor:UIColorFromRGB(color)];
	
	/* background image (TODO: image caching) */
	UIImage *backgroundImage = [DashUtils loadImageResource:item.background_uri userDataDir:context.account.cacheURL];
	[self.switchItemContainer.backgroundImageView setImage:backgroundImage];

	/* label */
	[self.itemLabel setText:item.label];
	
	/* error info */
	//TODO:
	[self showErrorInfo:NO error2:NO];

}

@end
