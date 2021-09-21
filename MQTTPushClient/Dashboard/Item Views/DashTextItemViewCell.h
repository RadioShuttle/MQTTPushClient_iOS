/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashCollectionViewCell.h"

@interface DashTextItemViewCell : DashCollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *textItemLabel;
@property (weak, nonatomic) IBOutlet UIView *textItemContainer;
@end
