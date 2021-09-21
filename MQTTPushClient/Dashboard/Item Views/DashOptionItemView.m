/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashOptionItemView.h"

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
    self.valueLabel = [[UILabel alloc] init];
    // self.valueLabel.textColor = [UIColor blackColor];
    self.valueLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.valueLabel setTextAlignment:NSTextAlignmentCenter];
    self.valueLabel.numberOfLines = 0;
    
    self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:self.valueLabel];
    
    [self.valueLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
    [self.valueLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
    [self.valueLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0].active = YES;
    [self.valueLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0].active = YES;
}

-(void) initTableView {
    _optionListTableView = [[UITableView alloc] init];
    _optionListTableView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:_optionListTableView];

    [_optionListTableView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
    [_optionListTableView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
    [_optionListTableView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0].active = YES;
    [_optionListTableView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0].active = YES;
}

@end
