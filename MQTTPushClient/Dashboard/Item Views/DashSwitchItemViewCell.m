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
	int64_t buttonBGColor;
	NSString *buttonTitle;
	NSString *imageURI;
	if ([switchItem isOnState]) {
		buttonTitle = switchItem.val;
		buttonTintColor = switchItem.color;
		buttonBGColor = switchItem.bgcolor;
		imageURI = switchItem.uri;
	} else {
		buttonTitle = switchItem.valOff;
		buttonTintColor = switchItem.colorOff;
		buttonBGColor = switchItem.bgcolorOff;
		imageURI = switchItem.uriOff;
	}
	UIColor *color;
	if (buttonTintColor == DASH_COLOR_CLEAR || buttonTintColor == DASH_COLOR_OS_DEFAULT) {
		UIColor *textColor = [UILabel new].textColor;
		color = textColor;
	} else {
		color = UIColorFromRGB(buttonTintColor);
	}
	[self.switchItemContainer.button setTintColor:color];

	if (buttonBGColor == DASH_COLOR_CLEAR) {
		color = nil;
	} else if (buttonBGColor == DASH_COLOR_OS_DEFAULT) {
		UIColor *textColor = [UIButton new].backgroundColor;
		color = textColor;
	} else {
		color = UIColorFromRGB(buttonBGColor);
	}
	[self.switchItemContainer.button setBackgroundColor:color];

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
		if (buttonTintColor == DASH_COLOR_CLEAR || buttonTintColor == DASH_COLOR_OS_DEFAULT) { // no image visibile? use label color for text button
			UIColor *textColor = [UILabel new].textColor;
			[self.switchItemContainer.button setTintColor:textColor];
		}
		[self.switchItemContainer.button setImage:nil forState:UIControlStateNormal];
		[self.switchItemContainer.button setTitle:buttonTitle forState:UIControlStateNormal];
	}

	/* background color */
	if (item.background == DASH_COLOR_OS_DEFAULT) {
		color = UIColorFromRGB(DASH_DEFAULT_CELL_COLOR); //TODO: dark mode use color from asset
	} else {
		color = UIColorFromRGB(item.background);
	}
	[self.switchItemContainer setBackgroundColor:color];
	
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
