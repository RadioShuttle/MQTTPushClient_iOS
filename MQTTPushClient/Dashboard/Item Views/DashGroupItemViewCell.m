/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashGroupItemViewCell.h"
#import "DashConsts.h"
#import "DashUtils.h"
#import "DashCollectionViewCell.h"

@interface DashGroupItemViewCell()
@property BOOL showAccountInfo;
@end

@implementation DashGroupItemViewCell

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {

	CGFloat labelheight =  (self.showAccountInfo ? self.layoutInfo.accountLabelHeight : 0);
	BOOL updateConstraints = NO;
	 
	 if (self.accountLabelHeightConstraint.constant != labelheight) {
		 self.accountLabelHeightConstraint.constant = labelheight;
		 updateConstraints = YES;
	 }
	
    if (self.layoutInfo && self.groupViewLeadingConstraint.constant != self.layoutInfo.marginLR) {
        self.groupViewLeadingConstraint.constant = self.layoutInfo.marginLR;
        self.groupViewTrailingConstraint.constant = self.layoutInfo.marginLR;
		updateConstraints = YES;
    }
	
	if (updateConstraints) {
		[self.headerViewContainer setNeedsUpdateConstraints];
	}

    return layoutAttributes;
}

-(void)onBind:(DashItem *)item layoutInfo:(DashCollectionViewLayoutInfo *)layoutInfo pos:(NSIndexPath *) pos account:(Account *)account selected:(BOOL)selected {
	self.pos = pos;
	self.layoutInfo = layoutInfo;
	self.showAccountInfo = pos.section == 0;
	if (!self.showAccountInfo) {
		self.accountLabel.text = nil;
	} else {
		self.accountLabel.text = account.accountDescription;
	}
	
	UIColor *textColor;
	int64_t color = item.textcolor;
	if (color == DASH_COLOR_OS_DEFAULT) {
		textColor = [UILabel new].textColor;
	} else {
		textColor = UIColorFromRGB(color);
	}

	if (item.background == DASH_COLOR_OS_DEFAULT) {
		[self.groupViewContainer setBackgroundColor:[UIColor colorNamed:@"Color_Item_Background"]];
	} else {
		[self.groupViewContainer setBackgroundColor:UIColorFromRGB(item.background)];
	}
	
	[self.groupLabel setTextColor:textColor];
	[self.groupLabel setText:item.label];
	
	CGFloat labelFontSize = [DashUtils getLabelFontSize:item.textsize];
	self.groupLabel.font = [self.groupLabel.font fontWithSize:labelFontSize];
	
	if (!self.tagGestureRecognizer) {
		self.tagGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onGroupViewLabelClicked)];
		self.tagGestureRecognizer.delaysTouchesBegan = YES;
		self.tagGestureRecognizer.numberOfTapsRequired = 1;
		[self addGestureRecognizer:self.tagGestureRecognizer];
	}
	
	if (selected) {
		[self showCheckmark];
	} else {
		[self hideCheckmark];
	}
}

-(void)onGroupViewLabelClicked {
	[self.groupSelectionHandler onGroupItemSelected:self.pos.section];
}

-(void)showCheckmark {
	if (!self.checkmarkView) {
		self.checkmarkView = [DashCollectionViewCell createCheckmarkView:self.groupViewContainer yOffset:0];
	}
	self.checkmarkView.hidden = NO;
	[self bringSubviewToFront:self.checkmarkView];
}

-(void)hideCheckmark {
	if (self.checkmarkView) {
		self.checkmarkView.hidden = YES;
		[self sendSubviewToBack:self.checkmarkView];
	}
}

@end
