/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import UIKit;
#import "DashItem.h"
#import "Dashboard.h"

@interface DashCollectionViewCell : UICollectionViewCell
@property DashItem *dashItem;

-(void)onBind:(DashItem *)item context:(Dashboard *)context;

@end
