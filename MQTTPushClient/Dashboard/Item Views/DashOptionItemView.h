/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashItemView.h"
#import "DashOptionItem.h"

@interface DashOptionItemView : DashItemView <UITableViewDataSource, UITableViewDelegate>

@property UILabel *valueLabel;
@property UIImageView *valueImageView;
@property NSLayoutConstraint *valueLabelTopConstraint;
@property UITableView *optionListTableView;

@property DashOptionItem *optionItem;
@property BOOL tableViewInitialized;
@property NSIndexPath *currentSelection;

@property Dashboard *context;

@end
