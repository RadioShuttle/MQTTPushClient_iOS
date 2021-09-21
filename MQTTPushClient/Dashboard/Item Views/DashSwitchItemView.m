/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashSwitchItemView.h"

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

-(void) initSwitchView {
    // self.button = [[UIButton alloc] init];
    self.button = [UIButton buttonWithType:UIButtonTypeSystem];
    // [self.button setTintColor:[UIColor redColor]];
    
    // [self.button setTitleColor:[UIColor redColor] forState:(UIControlStateHighlighted | UIControlStateNormal | UIControlStateSelected)];
    
    self.button.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:self.button];
    
    [self.button.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16.0].active = YES;
    [self.button.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16.0].active = YES;
    [self.button.topAnchor constraintEqualToAnchor:self.topAnchor constant:16.0].active = YES;
    [self.button.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-16.0].active = YES;
}


@end
