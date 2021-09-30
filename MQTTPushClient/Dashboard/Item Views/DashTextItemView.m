/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashTextItemView.h"
#import "DashTextItemViewCell.h"

#import "DashConsts.h"
#import "DashUtils.h"
#import "DashTextItem.h"

#
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
	[super addBackgroundImageView];
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
    UIImage *btnImage = [UIImage imageNamed:@"send"];
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

-(void)onBind:(DashItem *)item context:(Dashboard *)context {
	[super onBind:item context:context];
	
	DashTextItem *textItem = (DashTextItem *) item;
	
	/* set value text label */
	if (!textItem.content) {
		[self.valueLabel setText:@""];
	} else {
		[self.valueLabel setText:textItem.content];
	}
	
	/* text color */
	uint64_t color;
	if (textItem.textcolor == DASH_COLOR_OS_DEFAULT) {
		UIColor *defaultLabelColor = [UILabel new].textColor;
		[self.valueLabel setTextColor:defaultLabelColor];
	} else {
		[self.valueLabel setTextColor:UIColorFromRGB(textItem.textcolor)];
	}
	
	/* font size (TODO: consider moving to utility class */
	// UILabel * tmp = [UILabel new]; CGFloat labelFontSize = [tmp.font pointSize];
	CGFloat labelFontSize = 17.0f;
	int dashFontSize = item.textsize; // 0 - default, 1 small, 2 medium, 3 large
	if (dashFontSize == 0) { // use system default?
		dashFontSize = 2; // then use medium
	}
	if (dashFontSize == 1) {
		labelFontSize -= 2;
	} else if (dashFontSize == 3) {
		labelFontSize += 2;
	}
	self.valueLabel.font = [self.valueLabel.font fontWithSize:labelFontSize];
}

@end
