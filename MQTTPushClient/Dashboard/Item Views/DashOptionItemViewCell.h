/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCollectionViewCell.h"
#import "DashOptionItemView.h"

@interface DashOptionItemViewCell : DashCollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *itemLabel;
@property (weak, nonatomic) IBOutlet DashOptionItemView *itemContainer;

@end
