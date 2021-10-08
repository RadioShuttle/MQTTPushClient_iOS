/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCustomItemViewCell.h"

@implementation DashCustomItemViewCell

-(void)onBind:(DashItem *)item context:(Dashboard *)context {
	[super onBind:item context:context];
	
	if (self.webviewContainer.userInteractionEnabled) {
		self.webviewContainer.userInteractionEnabled = NO;
	};
	[self.webviewContainer onBind:item context:context];

	/* label */
	[self.customItemLabel setText:item.label];
}

-(void)prepareForReuse {
	
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
	return [super initWithCoder:aDecoder];
}

-(instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	DashCustomItemView *cv = [[DashCustomItemView alloc] init];
	cv.translatesAutoresizingMaskIntoConstraints = NO;
	[self.contentView addSubview:cv];
	
	UILabel *label = [[UILabel alloc] init];
	label.translatesAutoresizingMaskIntoConstraints = NO;
	[self.contentView addSubview:label];

	label.textAlignment = NSTextAlignmentCenter;
	label.lineBreakMode = NSLineBreakByTruncatingTail;
	
	[label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0].active = YES;
	[label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
	[label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
	
	[cv.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0].active = YES;
	[cv.bottomAnchor constraintEqualToAnchor:label.topAnchor constant:0.0].active = YES;
	[cv.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
	[cv.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
	
	self.webviewContainer = cv;
	self.customItemLabel = label;
	
	return self;
	
}


@end
