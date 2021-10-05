/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashCollectionFlowLayout.h"
#import "DashItem.h"

@interface DashGroupItemViewCell : UICollectionReusableView
@property (weak, nonatomic) IBOutlet UILabel *groupViewLabel;
@property (weak, nonatomic) IBOutlet UIView *groupViewContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupViewTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupViewLeadingConstraint;
@property (weak) DashCollectionViewLayoutInfo *layoutInfo;

-(void)onBind:(DashItem *)item layoutInfo:(DashCollectionViewLayoutInfo *)layoutInfo;

@end
