/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "DashCustomItemView.h"
#import "DashCollectionViewCell.h"

@interface DashCustomItemViewCell : DashCollectionViewCell <DashCustomViewContainer>
@property (weak, nonatomic) IBOutlet DashCustomItemView *webviewContainer;
@property (weak, nonatomic) IBOutlet UILabel *customItemLabel;

@property Dashboard *dashboard;

@end
