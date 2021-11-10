/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>

/* transparent background and white filled circle with padding 2 is the default */
@interface DashCircleBackroundView : UIView
- (instancetype)initWithColor:(UIColor*) color;
@property UIColor *fillColor;

@property int padding;
@end
