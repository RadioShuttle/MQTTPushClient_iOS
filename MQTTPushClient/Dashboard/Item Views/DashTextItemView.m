/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashTextItemView.h"
#import "DashTextItemViewCell.h"

@implementation DashTextItemView {
    NSLayoutConstraint *labelBottomConstraint;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initTextView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initTextView];
    }
    return self;
}

-(void) initTextView {
	
	self.backgroundImageView = [[UIImageView alloc] init];
	self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
	// self.backgroundImageView.clipsToBounds = YES;
	self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.backgroundImageView];
	[self.backgroundImageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
	[self.backgroundImageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
	[self.backgroundImageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0].active = YES;
	[self.backgroundImageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0].active = YES;


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
    labelBottomConstraint = [self.valueLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0]; // this constraint will be removed when calling showInputElements
    labelBottomConstraint.active = YES;
}

- (void)showInputElements {
    CGFloat margin = 8;
    
    /* Add stack view */
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.spacing = margin;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    
    /* Add input field to stack view*/
    self.inputTextField = [[UITextField alloc] init];
    self.inputTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.inputTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.inputTextField setBorderStyle:UITextBorderStyleBezel];
    [self.inputTextField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.inputTextField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [stackView addArrangedSubview:self.inputTextField];

    /* Add button to stack view */
    self.submitButton = [[UIButton alloc] init];
    UIImage *btnImage = [UIImage imageNamed:@"baseline_send_black_24pt"];
    [self.submitButton setImage:btnImage forState:UIControlStateNormal];
    [self.submitButton setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [self.submitButton setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [self.submitButton addTarget:self action:@selector(submitButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [stackView addArrangedSubview:self.submitButton];

    [self addSubview:stackView];
    
    CGFloat calcHeight = MAX(self.inputTextField.intrinsicContentSize.height, self.submitButton.intrinsicContentSize.height);
    [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:margin].active = YES;
    [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-margin].active = YES;
    [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-margin].active = YES;
    [stackView.heightAnchor constraintEqualToConstant:calcHeight].active = YES;
    
    /* remove constraint, label will shrink because we add an input field and button without increasing height */
    if (labelBottomConstraint.isActive) {
        [labelBottomConstraint setActive:NO];
    }
    /* bottom of label to top of stack view! */
    [self.valueLabel.bottomAnchor constraintEqualToAnchor:stackView.topAnchor constant:0.0].active = YES;   
}

- (void)submitButtonClicked:(UIButton*)button
{
    [self.valueLabel setText:self.inputTextField.text];
}

@end
