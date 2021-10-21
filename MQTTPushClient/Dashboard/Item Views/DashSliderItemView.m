/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashSliderItemView.h"
#import "DashSliderItem.h"
#import "DashUtils.h"
#import "DashConsts.h"
#import "Utils.h"

@implementation DashSliderItemView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];
    if (self) {
        [self initViews];
    }
    return self;

}

-(void) initViews {

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

	self.progressView = [[UIProgressView alloc] init];
	self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
	
	// self.progressView.transform = CGAffineTransformMakeScale(1.0f, 3.0f);

    [container addSubview:self.progressView];

    [self.progressView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16].active = YES;
    [self.progressView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16].active = YES;
    
    [self.progressView.centerYAnchor constraintEqualToAnchor:container.centerYAnchor constant:0].active = YES;

}

- (void)initInputElements {
	self.progressView.hidden = YES;
	UIView *container = [self.progressView superview];

	self.sliderCtrl = [[UISlider alloc] init];
	self.sliderCtrl.translatesAutoresizingMaskIntoConstraints = NO;
	
	[container addSubview:self.sliderCtrl];
	
	[self.sliderCtrl.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16].active = YES;
	[self.sliderCtrl.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16].active = YES;
	
	[self.sliderCtrl.centerYAnchor constraintEqualToAnchor:container.centerYAnchor constant:0].active = YES;

	[self.sliderCtrl addTarget:self action:@selector(onSliderTouchedDown:) forControlEvents:UIControlEventTouchDown];
	[self.sliderCtrl addTarget:self action:@selector(onSliderTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
	[self.sliderCtrl addTarget:self action:@selector(onSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)onSliderTouchedDown:(UISlider *)sliderCtrl {
	// NSLog(@"onSliderClicked");
	self.sliderPressed = YES;
}

- (void)onSliderTouchUpInside:(UISlider *)sliderCtrl {
	// NSLog(@"onSliderReleased");
	self.sliderPressed = NO;
}

-(void)onSliderValueChanged:(UISlider *)sliderCtrl {
	self.formattedSliderValue = [self format:sliderCtrl.value * 100.0f percent:self.displayPC];
	[self updateValueLabel];
}

- (void)onBind:(DashItem *)item context:(Dashboard *)context {
	[super onBind:item context:context];
	
	DashSliderItem *sliderItem = (DashSliderItem *) item;

	UIColor *progressTintColor = nil;
	UIColor *trackTintColor = nil;

	double progress = [DashSliderItem calcProgressInPercent:[sliderItem.content doubleValue] min:sliderItem.range_min max:sliderItem.range_max];
	
	self.formatter = [[NSNumberFormatter alloc] init];
	[self.formatter setMaximumFractionDigits:sliderItem.decimal >= 0 ? sliderItem.decimal : 0];
	[self.formatter setRoundingMode: NSNumberFormatterRoundHalfUp];
	
	self.formattedValue = [self format:progress percent:sliderItem.percent];
	
	int64_t color = sliderItem.progresscolor;

	if (color == DASH_COLOR_OS_DEFAULT) {
		progressTintColor = nil;
		trackTintColor = nil;
	} else {
		progressTintColor = UIColorFromRGB(color);
		CGFloat r, g, b, a;
		[progressTintColor getRed:&r green:&g blue:&b alpha:&a];
		trackTintColor = [UIColor colorWithRed:r green:g blue:b alpha:.3];
	}
	if (self.detailView && self.publishEnabled) {
		self.progressView.hidden = YES;
		self.sliderCtrl.hidden = NO;
		[self.sliderCtrl setValue:progress / 100.0f];
		[self.sliderCtrl setThumbTintColor:progressTintColor];
		[self.sliderCtrl setMinimumTrackTintColor:progressTintColor];
		[self.sliderCtrl setMaximumTrackTintColor:trackTintColor];
		self.formattedSliderValue = [self format:progress percent:sliderItem.percent];
		self.displayPC = sliderItem.percent;
	} else {
		self.sliderCtrl.hidden = YES;
		self.progressView.hidden = NO;
		[self.progressView setProgress:progress / 100.0f];
		[self.progressView setProgressTintColor:progressTintColor];
		[self.progressView setTrackTintColor:trackTintColor];
		self.formattedSliderValue = nil;
	}	
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

	[self updateValueLabel];
}

-(void)updateValueLabel {
	NSString *label;
	if (self.detailView && self.publishEnabled && ![Utils isEmpty:self.formattedSliderValue] ) {
		label = [NSString stringWithFormat:@"%@ / %@", self.formattedValue, self.formattedSliderValue];
	} else {
		label = self.formattedValue;
	}
	[self.valueLabel setText:label];
}

- (NSString *)format:(double)value percent:(BOOL)pc {
	NSString * formattedValue = [self.formatter stringFromNumber:[NSNumber numberWithDouble:value]];
	if (pc) {
		formattedValue = [NSString stringWithFormat:@"%@%%", formattedValue];
	}
	return formattedValue;
}


@end
