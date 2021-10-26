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
	
	CGFloat margin;
	if (self.detailView) {
		margin = 42.0;
	} else {
		margin = 16.0;
	}
    
    [self.button.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:margin].active = YES;
    [self.button.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-margin].active = YES;
    [self.button.topAnchor constraintEqualToAnchor:self.topAnchor constant:margin].active = YES;
    [self.button.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-margin].active = YES;
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
	
	if (buttonBGColor == DASH_COLOR_CLEAR || buttonBGColor == DASH_COLOR_OS_DEFAULT) {
		color = UIColorFromRGB(DASH_DEFAULT_CELL_COLOR); //TODO: dark mode;
	} else {
		color = UIColorFromRGB(buttonBGColor);
	}
	[self.button setBackgroundColor:color];
	
	/* set highlight color/image */
	UIImage *highlightColorImg = [DashUtils imageWithColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.3f]];
	[self.button setBackgroundImage:highlightColorImg forState:UIControlStateHighlighted];
	
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
