/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashSliderItemView.h"
#import "DashSliderItem.h"
#import "DashUtils.h"
#import "DashConsts.h"

@implementation DashSliderItemView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initViews:NO]; // add view with progress bar
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];
    if (self) {
        [self initViews:YES]; // add view with slider
    }
    return self;

}

-(void) initViews:(BOOL)slider {

    /* label */
    self.valueLabel = [[UILabel alloc] init];
    self.valueLabel.textAlignment = NSTextAlignmentCenter;
    self.valueLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.valueLabel.numberOfLines = 0;

    self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:self.valueLabel];

    [self.valueLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0].active = YES;
    [self.valueLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0].active = YES;
    [self.valueLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:0].active = YES;
    [self.valueLabel.bottomAnchor constraintEqualToAnchor:self.centerYAnchor constant:0].active = YES;

    /* add container for progress view (for alignment only) */
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:container];

    [container.topAnchor constraintEqualToAnchor:self.valueLabel.bottomAnchor constant:0].active = YES;
    
    [container.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0].active = YES;
    [container.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-0].active = YES;
    [container.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0].active = YES;

    UIView *addedView;
    if (slider) {
        self.sliderCtrl = [[UISlider alloc] init];
        self.sliderCtrl.translatesAutoresizingMaskIntoConstraints = NO;
        addedView = self.sliderCtrl;
    } else {
        self.progressView = [[UIProgressView alloc] init];
        self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.progressView.transform = CGAffineTransformMakeScale(1.0f, 3.0f);
        
        addedView = self.self.progressView;
    }
    [container addSubview:addedView];

    [addedView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16].active = YES;
    [addedView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16].active = YES;
    
    [addedView.centerYAnchor constraintEqualToAnchor:container.centerYAnchor constant:0].active = YES;

}

- (void)onBind:(DashItem *)item context:(Dashboard *)context {
	[super onBind:item context:context];
	
	DashSliderItem *sliderItem = (DashSliderItem *) item;

	UIColor *progressTintColor = nil;
	UIColor *trackTintColor = nil;

	double progress = [DashSliderItem calcProgressInPercent:[sliderItem.content doubleValue] min:sliderItem.range_min max:sliderItem.range_max];
	
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	[formatter setMaximumFractionDigits:sliderItem.decimal];
	[formatter setRoundingMode: NSNumberFormatterRoundHalfUp];
	
	NSString * val = [formatter stringFromNumber:[NSNumber numberWithFloat:progress]];
	if (sliderItem.percent) {
		val = [NSString stringWithFormat:@"%@%%", val];
	}
	
	[self.valueLabel setText:val];
	
	int64_t color = sliderItem.progresscolor;
	[self.progressView setProgress:progress / 100.0f];
	if (color == DASH_COLOR_OS_DEFAULT) {
		progressTintColor = nil;
		trackTintColor = nil;
	} else {
		progressTintColor = UIColorFromRGB(color);
		CGFloat r, g, b, a;
		[progressTintColor getRed:&r green:&g blue:&b alpha:&a];
		trackTintColor = [UIColor colorWithRed:r green:g blue:b alpha:.3];
	}
	[self.progressView setProgressTintColor:progressTintColor];
	[self.progressView setTrackTintColor:trackTintColor];

	/* text color */
	color = sliderItem.textcolor;
	if (color == DASH_COLOR_OS_DEFAULT) {
		UIColor *defaultLabelColor = [UILabel new].textColor;
		[self.valueLabel setTextColor:defaultLabelColor];
	} else {
		[self.valueLabel setTextColor:UIColorFromRGB(color)];
	}
	
	CGFloat labelFontSize = [DashUtils getLabelFontSize:item.textsize];
	self.valueLabel.font = [self.valueLabel.font fontWithSize:labelFontSize];

}


@end
