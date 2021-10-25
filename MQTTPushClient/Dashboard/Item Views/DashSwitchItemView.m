/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashSwitchItemView.h"
#import "DashSwitchItem.h"
#import "DashConsts.h"
#import "DashUtils.h"

@implementation DashSwitchItemView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initSwitchView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initSwitchView];
    }
    return self;
}

- (instancetype)initDetailViewWithFrame:(CGRect)frame {
	self = [super initDetailViewWithFrame:frame];
	if (self) {
		[self initSwitchView];
		[self initInputElements];
	}
	return self;
}

-(void) initSwitchView {
	self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    self.button.translatesAutoresizingMaskIntoConstraints = NO;    
    [self addSubview:self.button];
    
    [self.button.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16.0].active = YES;
    [self.button.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16.0].active = YES;
    [self.button.topAnchor constraintEqualToAnchor:self.topAnchor constant:16.0].active = YES;
    [self.button.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-16.0].active = YES;
}

- (void)initInputElements {
	[self.button addTarget:self action:@selector(buttonClicked) forControlEvents:UIControlEventTouchUpInside];
}

-(void)onBind:(DashItem *)item context:(Dashboard *)context {
	[super onBind:item context:context];
	
	DashSwitchItem *switchItem = (DashSwitchItem *) item;

	int64_t buttonTintColor;
	int64_t buttonBGColor;
	NSString *buttonTitle;
	NSString *imageURI;
	if ([switchItem isOnState]) {
		buttonTitle = switchItem.val;
		buttonTintColor = switchItem.color;
		buttonBGColor = switchItem.bgcolor;
		imageURI = switchItem.uri;
	} else {
		buttonTitle = switchItem.valOff;
		buttonTintColor = switchItem.colorOff;
		buttonBGColor = switchItem.bgcolorOff;
		imageURI = switchItem.uriOff;
	}
	
	UIColor *color;
	
	if (buttonBGColor == DASH_COLOR_CLEAR) {
		color = nil;
	} else if (buttonBGColor == DASH_COLOR_OS_DEFAULT) {
		UIColor *textColor = [UIButton new].backgroundColor;
		color = textColor;
	} else {
		color = UIColorFromRGB(buttonBGColor);
	}
	[self.button setBackgroundColor:color];
	
	UIImage *image;
	if (imageURI.length > 0) {
		//TODO: caching
		image = [DashUtils loadImageResource:imageURI userDataDir:context.account.cacheURL];
	}
	
	if (buttonTintColor == DASH_COLOR_CLEAR) {
		color = nil;
		if ([DashUtils isInternalResource:imageURI] || !image) {
			/* internal resource? use default label color (as we do not want blue buttons. Same for buttons without images too. */
			color = [UILabel new].textColor;
		} else {
			color = nil;
		}
	} else if (buttonTintColor == DASH_COLOR_OS_DEFAULT) {
		if ([DashUtils isUserResource:imageURI]) {
			image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		}
		color = [UILabel new].textColor;
	} else {
		if ([DashUtils isUserResource:imageURI]) {
			image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		}
		color = UIColorFromRGB(buttonTintColor);
	}
	
	if (image) {
		self.button.imageView.contentMode = UIViewContentModeScaleAspectFit;
		self.button.imageEdgeInsets = UIEdgeInsetsMake(16,16,16,16);
		self.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
		[self.button setImage:image forState:UIControlStateNormal];
		self.button.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
		[self.button setTitle:nil forState:UIControlStateNormal];
		[self.button setTintColor:color];
	} else {
		[self.button setImage:nil forState:UIControlStateNormal];
		[self.button setTitle:buttonTitle forState:UIControlStateNormal];
		self.button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		self.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		[self.button setTitleColor:color forState:UIControlStateNormal];
	}
	

}

-(void)buttonClicked {
	//TODO
	NSLog(@"publish ... ");
}

@end
