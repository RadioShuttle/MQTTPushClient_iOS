/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashOptionItemView.h"
#import "DashOptionItem.h"
#import "Utils.h"
#import "DashConsts.h"
#import "DashUtils.h"

@implementation DashOptionItemView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initTextView]; // cell view
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self initTableView]; // detail view
    }
    return self;
}

-(void) initTextView {
	[super addBackgroundImageView];
	
	self.valueImageView =  [[UIImageView alloc] init];
	self.valueImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.valueImageView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.valueImageView];
	[self.valueImageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
	[self.valueImageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
	[self.valueImageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0].active = YES;
	[self.valueImageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0].active = YES;
	
	
    self.valueLabel = [[UILabel alloc] init];
    // self.valueLabel.textColor = [UIColor blackColor];
    self.valueLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.valueLabel setTextAlignment:NSTextAlignmentCenter];
    self.valueLabel.numberOfLines = 0;
    
    self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:self.valueLabel];
    
    [self.valueLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
    [self.valueLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
    self.valueLabelTopConstraint = [self.valueLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0];
	self.valueLabelTopConstraint.active = YES;
    [self.valueLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0].active = YES;
}

-(void) initTableView {
	//TODO:
	[super addBackgroundImageView];
    self.optionListTableView = [[UITableView alloc] init];
    self.optionListTableView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:_optionListTableView];

    [self.optionListTableView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
    [self.optionListTableView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
    [self.optionListTableView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0].active = YES;
    [self.optionListTableView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0].active = YES;
}

- (void)onBind:(DashItem *)item context:(Dashboard *)context {
	[super onBind:item context:context];
	
	DashOptionItem *optionItem = (DashOptionItem *) item;
	
	NSString *txt = optionItem.content;
	DashOptionListItem *e;
	NSString *imageURI;
	for(int i = 0; i < optionItem.optionList.count; i++) {
		e = [optionItem.optionList objectAtIndex:i];
		if ([e.value isEqualToString:txt]) {
			imageURI = e.imageURI;
			if ([Utils isEmpty:e.displayValue]) {
				txt = e.value;
			} else {
				txt = e.displayValue;
			}
			break;
		}
	}
	
	UIImage *image;
	if (imageURI.length > 0) {
		//TODO: caching
		image = [DashUtils loadImageResource:imageURI userDataDir:context.account.cacheURL];
	}
	if (image) {
		self.valueImageView.contentMode = UIViewContentModeScaleAspectFit;
		[self.valueImageView setImage:image];
		/* tint internal image with default label color */
		UIColor *tintColor;
		if ([DashUtils isInternalResource:imageURI]) {
			tintColor = [UILabel new].textColor;
		} else {
			tintColor = nil;
		}
		[self.valueImageView setTintColor:tintColor];
		self.valueLabelTopConstraint.active = NO; // causes value label to be displayed at bottom
	} else {
		[self.valueImageView setImage:nil];
		self.valueLabelTopConstraint.active = YES;
	}
	
	/* set value text label */
	if (!txt) {
		[self.valueLabel setText:@""];
	} else {
		[self.valueLabel setText:txt];
	}
	
	/* text color */
	if (optionItem.textcolor == DASH_COLOR_OS_DEFAULT) {
		UIColor *defaultLabelColor = [UILabel new].textColor;
		[self.valueLabel setTextColor:defaultLabelColor];
	} else {
		[self.valueLabel setTextColor:UIColorFromRGB(optionItem.textcolor)];
	}
	
	CGFloat labelFontSize = [DashUtils getLabelFontSize:item.textsize];
	self.valueLabel.font = [self.valueLabel.font fontWithSize:labelFontSize];
}

@end
