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
#import "DashOptionTableViewCell.h"

@implementation DashOptionItemView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initTextView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self initTextView];
    }
    return self;
}

- (instancetype)initDetailViewWithFrame:(CGRect)frame {
	
	self = [super initDetailViewWithFrame:frame];
	if (self) {
		[self initTableView];
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
	// [super addBackgroundImageView];

	self.optionListTableView = [[UITableView alloc] init];
    self.optionListTableView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:self.optionListTableView];

    [self.optionListTableView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
    [self.optionListTableView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
    [self.optionListTableView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0].active = YES;
    [self.optionListTableView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0].active = YES;
	
	[self.optionListTableView registerClass:[DashOptionTableViewCell class] forCellReuseIdentifier:@"optionListItemCell"];
	self.optionListTableView.dataSource = self;
	self.optionListTableView.delegate = self;
}

- (void)onBind:(DashItem *)item context:(Dashboard *)context container:(id<DashItemViewContainer>)container {
	[super onBind:item context:context container:container];
	
	self.optionItem = (DashOptionItem *) item;
	if (self.detailView) {
		/* detail view */
		self.optionListTableView.backgroundColor = self.backgroundColor;
		if (!self.tableViewInitialized) {
			self.context = context;
			[self.optionListTableView reloadData];
			self.tableViewInitialized = YES;
		} else {
			/* update selection */
			NSIndexPath *sel;
			for(int i = 0; i < self.optionItem.optionList.count; i++) {
				if (self.optionItem.content.length > 0 && [self.optionItem.content isEqualToString:self.optionItem.optionList[i].value]) {
					sel = [NSIndexPath indexPathForRow:i inSection:0];
					break;
				}
			}
			NSMutableArray *upd = [NSMutableArray new];
			if (sel) {
				[upd addObject:sel];
				if (self.currentSelection && ![sel isEqual:self.currentSelection]) {
					[upd addObject:self.currentSelection];
				}
				[self.optionListTableView reloadRowsAtIndexPaths:upd withRowAnimation:NO];
			}
		}
	} else {
		/* collection cell view */
		
		NSString *txt = self.optionItem.content;
		DashOptionListItem *e;
		NSString *imageURI;
		for(int i = 0; i < self.optionItem.optionList.count; i++) {
			e = [self.optionItem.optionList objectAtIndex:i];
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
		if (![Utils isEmpty:imageURI]) {
			image = [DashUtils loadImageResource:imageURI userDataDir:context.account.cacheURL];
			if (!image) {
				self.imageError |= 4;
			}

		}
		if (image) {
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
		int64_t color = self.optionItem.textcolor;
		if (color == DASH_COLOR_OS_DEFAULT) {
			UIColor *defaultLabelColor = [UILabel new].textColor;
			[self.valueLabel setTextColor:defaultLabelColor];
		} else {
			[self.valueLabel setTextColor:UIColorFromRGB(color)];
		}
		
		CGFloat labelFontSize = [DashUtils getLabelFontSize:item.textsize];
		self.valueLabel.font = [self.valueLabel.font fontWithSize:labelFontSize];
	}
	[self handleBindErrors];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.optionItem.optionList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	DashOptionTableViewCell *cell = (DashOptionTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"optionListItemCell"];
	DashOptionListItem *listItem = self.optionItem.optionList[indexPath.row];
	BOOL selected = self.optionItem.content.length > 0 && [self.optionItem.content isEqualToString:listItem.value];
	if (selected) {
		self.currentSelection = indexPath;
	}
	[cell setBackgroundColor:[UIColor clearColor]]; // use cell background

	int64_t color = self.optionItem.textcolor;
	UIColor *textColor;
	if (color == DASH_COLOR_OS_DEFAULT || color == DASH_COLOR_CLEAR) {
		textColor = [[UILabel new] textColor];
	} else {
		textColor = UIColorFromRGB(color);
	}
	
	[cell onBind:listItem context:self.context selected:selected textColor:textColor];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	DashOptionListItem *listItem = self.optionItem.optionList[indexPath.row];

	BOOL selected = self.optionItem.content.length > 0 && [self.optionItem.content isEqualToString:listItem.value];
	
	/* if an option is already selected, a click does not deselect */
	if (!selected) {
		NSData * data = [(listItem.value == nil ? @"" : listItem.value) dataUsingEncoding:NSUTF8StringEncoding];
		[self performSend:data queue:NO];
	}
}

@end
