/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCollectionViewCell.h"
#import "DashConsts.h"

@implementation DashCollectionViewCell

-(void)onBind:(DashItem *)item context:(Dashboard *)context {
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
@end
