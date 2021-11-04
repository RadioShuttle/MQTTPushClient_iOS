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
	self.dashItem = item;
	
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

-(void)performSend:(NSData *)data queue:(BOOL)queue {
	[self performSend:self.dashItem.topic_p data:data retain:self.dashItem.retain_ queue:queue item:self.dashItem];
}

-(void) performSend:(NSString *)topic data:(NSData *)data retain:(BOOL)retain queue:(BOOL)queue item:(DashItem *)item {
	if (self.currentPublishID > 0) {
		if (!queue) {
			//TODO: display: Please wait until current request has been finished.
		} else {
			self.queue = data;
		}
	} else {
		self.currentPublishID = [self.publishController publish:topic payload:data retain:retain item:item];
	}
	[self showProgressBar];
}

- (void)showProgressBar {
	if (!self.progressBar) {
		self.progressBar = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
		if (self.dashItem.textcolor == DASH_COLOR_OS_DEFAULT || self.dashItem.textcolor == DASH_COLOR_CLEAR) {
			self.progressBar.color = [UILabel new].textColor;
		} else {
			self.progressBar.color = UIColorFromRGB(self.dashItem.textcolor);
		}
		self.progressBar.translatesAutoresizingMaskIntoConstraints = NO;
		[self.progressBar startAnimating];
		[self addSubview:self.progressBar];
		
		[self.progressBar.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0.0].active = YES;
		[self.progressBar.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0.0].active = YES;
		
		[self bringSubviewToFront:self.progressBar];
	}
}

- (void)hideProgressBar {
	if (self.progressBar) {
		[self.progressBar stopAnimating];
		[self.progressBar removeFromSuperview];
		self.progressBar = nil;
	}
}

-(BOOL) onPublishRequestFinished:(uint32_t) requestID {
	BOOL finished = NO;
	if (self.currentPublishID == requestID) {
		self.currentPublishID = 0;
		finished = YES;
		[self hideProgressBar];
	}
	return finished;
}

@end
