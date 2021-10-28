/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashItemView.h"
#import "DashConsts.h"
#import "DashUtils.h"
#import "Utils.h"

@implementation DashItemView

- (instancetype)initDetailViewWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	self.detailView = YES;
	return self;
}

-(void)onBind:(DashItem *)item context:(Dashboard *)context {

	int64_t color = item.background;
	/* background color */
	if (color == DASH_COLOR_OS_DEFAULT) {
		color = DASH_DEFAULT_CELL_COLOR; //TODO: dark mode use color from asset
	}
	
	[self setBackgroundColor:UIColorFromRGB(color)];
	
	/* background image (TODO: image caching) */
	if (self.backgroundImageView) {
		UIImage *backgroundImage = [DashUtils loadImageResource:item.background_uri userDataDir:context.account.cacheURL];
		[self.backgroundImageView setImage:backgroundImage];
	}
	self.dashVersion = context.localVersion;
	self.publishEnabled = !([Utils isEmpty:item.topic_p] && [Utils isEmpty:item.script_p]);
}

-(void)addBackgroundImageView {
	self.backgroundImageView =  [[UIImageView alloc] init];
	self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.backgroundImageView];
	[self.backgroundImageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
	[self.backgroundImageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
	[self.backgroundImageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0].active = YES;
	[self.backgroundImageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0].active = YES;
}

-(void)initInputElements {	
}

@end
