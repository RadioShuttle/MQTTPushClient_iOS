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

- (instancetype)initDetailViewWithFrame:(CGRect)frame {
	self = [super initDetailViewWithFrame:frame];
	if (self) {
		[self initViews];
		[self initInputElements];
	}
	return self;
}

-(void) initViews {
	[super addBackgroundImageView];

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
	self.updateProgressBarDisabled = YES;
}

- (void)onSliderTouchUpInside:(UISlider *)sliderCtrl {
	// NSLog(@"onSliderReleased");
	self.sliderPressed = NO;
}

-(void)onSliderValueChanged:(UISlider *)sliderCtrl {
	DashSliderItem *item = (DashSliderItem *) self.dashItem;
	if (item) {
		double f = sliderCtrl.value / sliderCtrl.maximumValue;
		double value = (item.range_max - item.range_min) * f + item.range_min;
		NSString *formattedVal = [self.formatterUS stringFromNumber:@(value)];
		NSData * data = [formattedVal dataUsingEncoding:NSUTF8StringEncoding];
		[self performSend:data queue:YES];
		
		if (self.displayPC) {
			self.formattedSliderValue = [self format:(f * 100) percent:YES];
		} else {
			self.formattedSliderValue = [self format:value percent:NO];
		}
		[self updateValueLabel];
	}
}

- (void)onBind:(DashItem *)item context:(Dashboard *)context {
	[super onBind:item context:context];
	
	DashSliderItem *sliderItem = (DashSliderItem *) item;

	UIColor *progressTintColor = nil;
	UIColor *trackTintColor = nil;
	
	self.formatter = [[NSNumberFormatter alloc] init];
	[self.formatter setMaximumFractionDigits:sliderItem.decimal >= 0 ? sliderItem.decimal : 0];
	[self.formatter setRoundingMode: NSNumberFormatterRoundHalfUp];
	
	self.formatterUS = [[NSNumberFormatter alloc] init];
	[self.formatterUS setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
	[self.formatterUS setMaximumFractionDigits:sliderItem.decimal >= 0 ? sliderItem.decimal : 0];
	[self.formatterUS setRoundingMode: NSNumberFormatterRoundHalfUp];
	
	/* calculate progress bar value (will be 0 if invalid/no data) */
	double progress = 0;
	self.formattedValue = sliderItem.content; // will be overwritten with formatted value
	if (![Utils isEmpty:sliderItem.error1]) {
		/* if java script error, there is no valid data, set progress bar to 0 */
	} else {
		if (![Utils isEmpty:sliderItem.content]) {
			NSScanner *scanner = [NSScanner scannerWithString:sliderItem.content];
			double v;
			if ([scanner scanDouble:&v]) {
				if (sliderItem.range_min < sliderItem.range_max && v >= sliderItem.range_min && v <= sliderItem.range_max) {
					progress = [DashSliderItem calcProgressInPercent:v min:sliderItem.range_min max:sliderItem.range_max];
					if (sliderItem.percent) {
						self.formattedValue = [self format:progress percent:YES];
					} else {
						self.formattedValue = [self format:v percent:NO];
					}
				}
			}
		}
	}
	
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
		if (!self.updateProgressBarDisabled) {
			[self.sliderCtrl setValue:progress / 100.0f];
			self.formattedSliderValue = self.formattedValue;
		}
		[self.sliderCtrl setThumbTintColor:progressTintColor];
		[self.sliderCtrl setMinimumTrackTintColor:progressTintColor];
		[self.sliderCtrl setMaximumTrackTintColor:trackTintColor];
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
