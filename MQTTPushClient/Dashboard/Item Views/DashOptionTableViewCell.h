/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashOptionListItem.h"
#import "Dashboard.h"

@interface DashOptionTableViewCell : UITableViewCell

@property UILabel *label;
@property UIImageView *itemImageView;

@property UIImageView *checkedImageView;
@property UIImageView *uncheckedImageView;

@property NSLayoutConstraint *itemImageWidthCstr;
@property NSLayoutConstraint *itemImageHeightCstr;
@property NSLayoutConstraint *labelTopCstr;

- (void)onBind:(DashOptionListItem *) optionListItem context:(Dashboard *)context selected:(BOOL)selected;
@end
