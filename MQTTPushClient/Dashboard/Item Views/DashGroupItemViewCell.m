/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashGroupItemViewCell.h"
#import "DashConsts.h"

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

-(void)onBind:(DashItem *)item layoutInfo:(DashCollectionViewLayoutInfo *)layoutInfo firstGroupEntry:(BOOL) firstGroupEntry account:(Account *)account {
	self.layoutInfo = layoutInfo;
	self.showAccountInfo = firstGroupEntry;
	if (!self.showAccountInfo) {
		self.accountLabel.text = nil;
	} else {
		self.accountLabel.text = account.accountDescription;
	}
	
	int64_t bg = item.background;
	if (bg == DASH_COLOR_OS_DEFAULT) {
		bg = DASH_DEFAULT_CELL_COLOR; // TODO: dark mode
	}
	
	UIColor *textColor;
	int64_t color = item.textcolor;
	if (color == DASH_COLOR_OS_DEFAULT) {
		textColor = [UILabel new].textColor;
	} else {
		textColor = UIColorFromRGB(color);
	}
	
	[self.groupViewContainer setBackgroundColor:UIColorFromRGB(bg)];
	[self.groupLabel setTextColor:textColor];
	[self.groupLabel setText:item.label];
	
}

@end
