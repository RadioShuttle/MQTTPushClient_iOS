/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCollectionViewCell.h"
#import "DashSliderItemView.h"

@interface DashSliderItemViewCell : DashCollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *itemLabel;
@property (weak, nonatomic) IBOutlet DashSliderItemView *itemContainer;

@end
