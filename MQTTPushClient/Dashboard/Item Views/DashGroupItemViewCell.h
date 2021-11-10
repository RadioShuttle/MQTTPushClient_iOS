/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashCollectionFlowLayout.h"
#import "DashItem.h"
#import "Account.h"

@class DashGroupItemViewCell;
@protocol DashGroupSelectionHandler
-(void)onGroupItemSelected:(NSInteger) section;
@end

@interface DashGroupItemViewCell : UICollectionReusableView
@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
@property (weak, nonatomic) IBOutlet UILabel *groupLabel;
@property (weak, nonatomic) IBOutlet UIView *headerViewContainer;
@property (weak, nonatomic) IBOutlet UIView *groupViewContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupViewTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *accountLabelHeightConstraint;

@property (weak) DashCollectionViewLayoutInfo *layoutInfo;
@property NSIndexPath *pos;
@property UITapGestureRecognizer *tagGestureRecognizer;
@property (weak) id<DashGroupSelectionHandler> groupSelectionHandler;
@property UIView *checkmarkView;

-(void)onBind:(DashItem *)item layoutInfo:(DashCollectionViewLayoutInfo *)layoutInfo pos:(NSIndexPath *) pos account:(Account *)account selected:(BOOL)selected;

-(void)showCheckmark;
-(void)hideCheckmark;

@end
