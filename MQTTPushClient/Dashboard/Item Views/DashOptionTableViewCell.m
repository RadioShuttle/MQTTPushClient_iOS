/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashOptionTableViewCell.h"
#import "Utils.h"
#import "DashUtils.h"
#import "DashConsts.h"

@implementation DashOptionTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

-(instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self initComponents];
	}
	return self;
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		[self initComponents];
	}
	return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)initComponents {
	UIImage *rb_checked = [[UIImage imageNamed:@"radio_button_checked"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	self.checkedImageView = [[UIImageView alloc] initWithImage:rb_checked];
	self.checkedImageView.hidden = YES;
	self.checkedImageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.checkedImageView.contentMode = UIViewContentModeScaleAspectFit;
	[self addSubview:self.checkedImageView];
	 
	[self.checkedImageView.widthAnchor constraintEqualToConstant:24].active = YES;
	[self.checkedImageView.heightAnchor constraintEqualToConstant:24].active = YES;
	[self.checkedImageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16].active = YES;
	[self.checkedImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;

	UIImage *rb_unchecked = [[UIImage imageNamed:@"radio_button_unchecked"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	self.uncheckedImageView = [[UIImageView alloc] initWithImage:rb_unchecked];
	self.uncheckedImageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.uncheckedImageView.contentMode = UIViewContentModeScaleToFill;
	[self addSubview:self.uncheckedImageView];
	
	[self.uncheckedImageView.widthAnchor constraintEqualToConstant:24].active = YES;
	[self.uncheckedImageView.heightAnchor constraintEqualToConstant:24].active = YES;
	[self.uncheckedImageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16].active = YES;
	[self.uncheckedImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;

	
	self.label = [[UILabel alloc] init];
	self.label.translatesAutoresizingMaskIntoConstraints = NO;
	self.label.lineBreakMode = NSLineBreakByTruncatingTail;
	[self.label setTextAlignment:NSTextAlignmentLeft];
	self.label.numberOfLines = 0;
	
	[self addSubview:self.label];

	[self.label.leadingAnchor constraintEqualToAnchor:self.checkedImageView.trailingAnchor constant:8].active = YES;
	[self.label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16].active = YES;
	self.labelTopCstr = [self.label.topAnchor constraintEqualToAnchor:self.topAnchor constant:4];
	self.labelTopCstr.active = YES;
	[self.label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-4].active = YES;

	self.itemImageView = [[UIImageView alloc] init];
	
	self.itemImageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.itemImageView.contentMode = UIViewContentModeScaleAspectFit;
	[self addSubview:self.itemImageView];

	self.itemImageWidthCstr = [self.itemImageView.widthAnchor constraintEqualToConstant:152];
	self.itemImageHeightCstr = [self.itemImageView.heightAnchor constraintEqualToConstant:152];
	[self.itemImageView.leadingAnchor constraintEqualToAnchor:self.checkedImageView.trailingAnchor constant:8].active = YES;
	[self.itemImageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:4].active = YES;
	[self.itemImageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-4].active = YES;
	[self.itemImageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16].active = YES;
	[self.heightAnchor constraintGreaterThanOrEqualToConstant:40].active = YES;
	
	[self setSelectedBackgroundView:[[UIView alloc] init]];
	[self.selectedBackgroundView setBackgroundColor:[UIColor darkGrayColor]];

	[self bringSubviewToFront:self.label];
}

- (void)onBind:(DashOptionListItem *) optionListItem context:(Dashboard *)context selected:(BOOL)selected textColor:(UIColor *)textColor {
	NSString *displayText = optionListItem.displayValue;
	if ([Utils isEmpty:optionListItem.imageURI] && [Utils isEmpty:optionListItem.displayValue]) {
		displayText = optionListItem.value;
	}
	self.checkedImageView.hidden = !selected;
	self.uncheckedImageView.hidden = selected;

	UIColor *highlightColor = [textColor colorWithAlphaComponent:.5];
	[self.selectedBackgroundView setBackgroundColor:highlightColor];
	
	/* text color */
	self.checkedImageView.tintColor = textColor;
	self.uncheckedImageView.tintColor = textColor;
	self.label.textColor = textColor;
	
	UIImage *image;
	if (optionListItem.imageURI.length > 0) {
		image = [DashUtils loadImageResource:optionListItem.imageURI userDataDir:context.account.cacheURL];
		[self.itemImageView setImage:image];
		self.itemImageWidthCstr.active = YES;
		self.itemImageHeightCstr.active = YES;
		self.labelTopCstr.active = NO;
		[self.label setTextAlignment:NSTextAlignmentCenter];
	} else {
		[self.itemImageView setImage:nil];
		self.itemImageWidthCstr.active = NO;
		self.itemImageHeightCstr.active = NO;
		self.labelTopCstr.active = YES;
		[self.label setTextAlignment:NSTextAlignmentLeft];
	}
	
	[self.label setText:displayText];
}

@end
