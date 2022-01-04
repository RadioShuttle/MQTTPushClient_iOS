/*
 * Copyright (c) 2022 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashImageCell.h"
#import "DashCircleBackroundView.h"

@interface DashImageCell ()
@property UIView *lockView;
@end

@implementation DashImageCell

-(void)showLock {
	if (!self.lockView) {
		[self createLockView];
	}
	self.lockView.hidden = NO;
	[self bringSubviewToFront:self.lockView];
}
-(void)hideLock {
	self.lockView.hidden = YES;
}

-(void)createLockView {
	DashCircleBackroundView *lockView = [[DashCircleBackroundView alloc] initWithColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
	lockView.drawBorder = YES;
	lockView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:lockView];
	int s = 24;
	
	[lockView.heightAnchor constraintEqualToConstant:s].active = YES;
	[lockView.widthAnchor constraintEqualToConstant:s].active = YES;
	[lockView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4].active = YES;
	[lockView.topAnchor constraintEqualToAnchor:self.topAnchor constant:18].active = YES;
	// [lockView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0].active = YES;
	
	UIImage *image = [[UIImage imageNamed:@"lock"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	int p = lockView.padding + 2;
	[imageView setTintColor:[UIColor blackColor]];
	imageView.translatesAutoresizingMaskIntoConstraints = NO;
	[lockView addSubview:imageView];
	[imageView.heightAnchor constraintEqualToConstant:s - p * 2].active = YES;
	[imageView.widthAnchor constraintEqualToConstant:s - p * 2].active = YES;
	[imageView.topAnchor constraintEqualToAnchor:lockView.topAnchor constant:p].active = YES;
	[imageView.leadingAnchor constraintEqualToAnchor:lockView.leadingAnchor constant:p].active = YES;
	self.lockView = lockView;
}

@end
