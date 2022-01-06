/*
 * Copyright (c) 2022 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "Dashboard.h"
#import "DashCollectionViewController.h"

@interface DashManageImagesController : UICollectionViewController <UICollectionViewDataSourcePrefetching,  UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreButton;

@property (weak, nonatomic) IBOutlet UILabel *statusBarLabel;

/* args */
@property DashCollectionViewController *parentCtrl;

@end
