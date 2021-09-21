/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashSliderItemView.h"

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
        
        self.progressView.transform = CGAffineTransformMakeScale(1.0f, 4.0f);
        
        addedView = self.self.progressView;
    }
    [container addSubview:addedView];

    [addedView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16].active = YES;
    [addedView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16].active = YES;
    
    [addedView.centerYAnchor constraintEqualToAnchor:container.centerYAnchor constant:0].active = YES;

}

@end
