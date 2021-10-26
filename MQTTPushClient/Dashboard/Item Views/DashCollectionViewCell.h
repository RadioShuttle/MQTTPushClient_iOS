/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import UIKit;
#import "DashItem.h"
#import "Dashboard.h"
#import "DashCircleBackroundView.h"

@interface DashCollectionViewCell : UICollectionViewCell
@property UIImageView *errorImageView1;
@property DashCircleBackroundView *backgroundView1;
@property UIImageView *errorImageView2;
@property DashCircleBackroundView *backgroundView2;
@property BOOL labelConstraintSet;

@property UIColor *labelColor;

-(void)onBind:(DashItem *)item context:(Dashboard *)context;
-(void)onBind:(DashItem *)item context:(Dashboard *)context label:(UILabel *)label;

-(void)showErrorInfo:(BOOL)error1 error2:(BOOL)error2;

@end
