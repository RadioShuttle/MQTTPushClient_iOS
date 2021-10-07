/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashGroupItemViewCell.h"
#import "DashConsts.h"

@implementation DashGroupItemViewCell

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {

    if (self.layoutInfo && self.groupViewLeadingConstraint.constant != self.layoutInfo.marginLR) {
        self.groupViewLeadingConstraint.constant = self.layoutInfo.marginLR;
        self.groupViewTrailingConstraint.constant = -self.layoutInfo.marginLR;
        [self.groupViewContainer setNeedsUpdateConstraints];
    }
    
    return layoutAttributes;
}

-(void)onBind:(DashItem *)item layoutInfo:(DashCollectionViewLayoutInfo *)layoutInfo {
	self.layoutInfo = layoutInfo;
	
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
	[self.groupViewLabel setTextColor:textColor];
	[self.groupViewLabel setText:item.label];
	
}

@end
