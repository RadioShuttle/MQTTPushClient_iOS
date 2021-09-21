/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashGroupItemView.h"

@implementation DashGroupItemView

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {

    if (self.layoutInfo && self.groupViewLeadingConstraint.constant != self.layoutInfo.marginLR) {
        self.groupViewLeadingConstraint.constant = self.layoutInfo.marginLR;
        self.groupViewTrailingConstraint.constant = -self.layoutInfo.marginLR;
        [self.groupViewContainer setNeedsUpdateConstraints];
    }
    
    return layoutAttributes;
}


@end
