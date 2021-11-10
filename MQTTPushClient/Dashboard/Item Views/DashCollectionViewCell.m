/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCollectionViewCell.h"
#import "DashConsts.h"
#import "Utils.h"

@implementation DashCollectionViewCell

-(void)onBind:(DashItem *)item context:(Dashboard *)context selected:(BOOL)selected {
	[self onBind:item context:context label:nil selected:selected];
}

-(void)onBind:(DashItem *)item context:(Dashboard *)context label:(UILabel *)label selected:(BOOL)selected {

	if (!self.labelConstraintSet) {
		/* get the height reserverd for label */
		CGFloat height = self.bounds.size.height - self.bounds.size.width;
		// label.translatesAutoresizingMaskIntoConstraints = NO;
		[label.heightAnchor constraintEqualToConstant:height].active = YES;
		self.labelConstraintSet = YES;
	}
	[label setText:item.label];

	BOOL error1 = ![Utils isEmpty:item.error1];
	BOOL error2 = ![Utils isEmpty:item.error2];
	
	[self showErrorInfo:error1 error2:error2];
	
	if (selected) {
		[self showCheckmark];
	} else {
		[self hideCheckmark];
	}
}

/* Displays one or two error images, indicating java script errors */
-(void)showErrorInfo:(BOOL)error1 error2:(BOOL)error2 {
	if (!self.errorImageView1) {
		self.labelColor = [[UILabel new] textColor];
		self.backgroundView1 = [[DashCircleBackroundView alloc] init];
		self.backgroundView1.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.backgroundView1];
		[self.backgroundView1.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-4.0].active = YES;
		[self.backgroundView1.topAnchor constraintEqualToAnchor:self.topAnchor constant:4.0].active = YES;
		[self.backgroundView1.heightAnchor constraintEqualToConstant:16.0].active = YES;
		[self.backgroundView1.widthAnchor constraintEqualToConstant:16.0].active = YES;

		self.errorImageView1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Error-Info"]];
		self.errorImageView1.translatesAutoresizingMaskIntoConstraints = NO;
		self.errorImageView1.tintColor = self.labelColor;
		[self addSubview:self.errorImageView1];
		
		[self.errorImageView1.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-4.0].active = YES;
		[self.errorImageView1.topAnchor constraintEqualToAnchor:self.topAnchor constant:4.0].active = YES;
		[self.errorImageView1.heightAnchor constraintEqualToConstant:16.0].active = YES;
		[self.errorImageView1.widthAnchor constraintEqualToConstant:16.0].active = YES;
	}
	if (!self.errorImageView2) {
		self.backgroundView2 = [[DashCircleBackroundView alloc] init];
		self.backgroundView2.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.backgroundView2];
		[self.backgroundView2.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-4.0].active = YES;
		[self.backgroundView2.trailingAnchor constraintEqualToAnchor:self.errorImageView1.leadingAnchor constant:-4.0].active = YES;
		[self.backgroundView2.topAnchor constraintEqualToAnchor:self.topAnchor constant:4.0].active = YES;
		
		[self.backgroundView2.heightAnchor constraintEqualToConstant:16.0].active = YES;
		[self.backgroundView2.widthAnchor constraintEqualToConstant:16.0].active = YES;
		
		self.errorImageView2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Error-Info"]];
		self.errorImageView2.translatesAutoresizingMaskIntoConstraints = NO;
		self.errorImageView2.tintColor = self.labelColor;
		[self addSubview:self.errorImageView2];
		
		[self.errorImageView2.trailingAnchor constraintEqualToAnchor:self.errorImageView1.leadingAnchor constant:-4.0].active = YES;
		[self.errorImageView2.topAnchor constraintEqualToAnchor:self.topAnchor constant:4.0].active = YES;
		
		[self.errorImageView2.heightAnchor constraintEqualToConstant:16.0].active = YES;
		[self.errorImageView2.widthAnchor constraintEqualToConstant:16.0].active = YES;
	}
	self.errorImageView1.hidden = !error1 && !error2;
	self.backgroundView1.hidden = self.errorImageView1.hidden;
	self.errorImageView2.hidden = !error1 || !error2;
	self.backgroundView2.hidden = self.errorImageView2.hidden;

}

-(void)showCheckmark {
	if (!self.checkmarkView) {
		self.checkmarkView = [DashCollectionViewCell createCheckmarkView:self yOffset:-12];
	}
	self.checkmarkView.hidden = NO;
	[self bringSubviewToFront:self.checkmarkView];
}

-(void)hideCheckmark {
	if (self.checkmarkView) {
		self.checkmarkView.hidden = YES;
		[self sendSubviewToBack:self.checkmarkView];
	}
}

+(UIView *) createCheckmarkView:(UIView *)container yOffset:(int) yOffset {
	UIView *checkmarkView = [[DashCircleBackroundView alloc] initWithColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.5]];
	((DashCircleBackroundView *) checkmarkView).padding = 0;
	checkmarkView.translatesAutoresizingMaskIntoConstraints = NO;
	[container addSubview:checkmarkView];
	
	[checkmarkView.heightAnchor constraintEqualToConstant:24].active = YES;
	[checkmarkView.widthAnchor constraintEqualToConstant:24].active = YES;
	[checkmarkView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:4].active = YES;
	[checkmarkView.centerYAnchor constraintEqualToAnchor:container.centerYAnchor constant:yOffset].active = YES;
	
	UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	[imageView setTintColor:[UIColor whiteColor]];
	imageView.translatesAutoresizingMaskIntoConstraints = NO;
	[checkmarkView addSubview:imageView];
	[imageView.heightAnchor constraintEqualToConstant:24].active = YES;
	[imageView.widthAnchor constraintEqualToConstant:24].active = YES;
	return checkmarkView;
}

@end
