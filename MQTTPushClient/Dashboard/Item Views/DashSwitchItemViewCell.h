/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashCollectionViewCell.h"
#import "DashSwitchItemView.h"

@interface DashSwitchItemViewCell : DashCollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *itemLabel;
@property (weak, nonatomic) IBOutlet DashSwitchItemView *switchItemContainer;

@end
