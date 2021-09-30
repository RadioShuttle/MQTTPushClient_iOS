/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashItem.h"
#import "Dashboard.h"

@interface DashItemView : UIView

@property UIImageView *backgroundImageView;

-(void)onBind:(DashItem *)item context:(Dashboard *)context;
/* call this to add an empty ImageView to this view. this should be called before adding any other elements (beacuase of layering) */
-(void)addBackgroundImageView;

@end
