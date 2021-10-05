/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashItemView.h"

@interface DashOptionItemView : DashItemView

@property UILabel *valueLabel;
@property UIImageView *valueImageView;
@property NSLayoutConstraint *valueLabelTopConstraint;
@property UITableView *optionListTableView;

@end
