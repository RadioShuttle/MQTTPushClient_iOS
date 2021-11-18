/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */
#import "DashTextItem.h"
#import "DashGroupItem.h"
#import "DashSwitchItem.h"
#import "DashSliderItem.h"
#import "DashOptionItem.h"
#import "DashCustomItem.h"
#import "DashConsts.h"

#import "DashEditItemViewController.h"

@interface DashEditItemViewController ()
@property NSMutableArray *textSizeDisplayValues;
@end

@implementation DashEditItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
	/* add prefix to title */
	NSString *prefix = (self.mode == Add ? @"Add" : @"Edit");
	self.navigationItem.title = [NSString stringWithFormat:@"%@ %@", prefix,self.navigationItem.title];
	
	self.tableView.separatorColor = [UIColor clearColor];
	self.tableView.allowsSelection = NO;

	/* 1. General section */

	/* label */
	self.labelTextField.text = self.item.label;
	
	/* group */
	if (self.mode == Add) {
		if (self.dashboard.groups.count > 0) {
			self.groupLabel.text = self.dashboard.groups.lastObject.label;
			self.selGroupIdx = (int) self.dashboard.groups.count - 1;
		} else {
			self.selGroupIdx = -1;
		}
	} else {
		self.selGroupIdx = [self getPosOfItem:self.item groupPos:YES];
		if (self.selGroupIdx >= 0) {
			self.groupLabel.text = self.dashboard.groups[self.selGroupIdx].label;
		}
	}
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onGroupButtonClicked)];
	tapGestureRecognizer.delaysTouchesBegan = YES;
	tapGestureRecognizer.numberOfTapsRequired = 1;
	self.groupLabel.userInteractionEnabled = YES;
	[self.groupLabel addGestureRecognizer:tapGestureRecognizer];
	[self.groupDropDownButon addTarget:self action:@selector(onGroupButtonClicked) forControlEvents:UIControlEventTouchUpInside];
	

	/* pos within group  */
	if ([self.item isKindOfClass:[DashGroupItem class]]) {
		if (self.mode == Add) {
			self.selPosIdx = (int) self.dashboard.groups.count;
		} else {
			self.selPosIdx = [self getPosOfItem:self.item groupPos:YES];
		}
	} else {
		if (self.mode == Add) {
			self.selPosIdx = [self getNoOfItemsInGroup:(int) self.dashboard.groups.count - 1];
		} else {
			self.selPosIdx = [self getPosOfItem:self.item groupPos:NO];
		}
	}
	self.posLabel.text = [@(self.selPosIdx + 1) stringValue];

	tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPosButtonClicked)];
	tapGestureRecognizer.delaysTouchesBegan = YES;
	tapGestureRecognizer.numberOfTapsRequired = 1;
	self.posLabel.userInteractionEnabled = YES;
	[self.posLabel addGestureRecognizer:tapGestureRecognizer];
	[self.posDropDownButton addTarget:self action:@selector(onPosButtonClicked) forControlEvents:UIControlEventTouchUpInside];
	
	/* text color */
	UIColor *color;
	CGFloat a,r,g,b;
	if (self.item.textcolor == DASH_COLOR_OS_DEFAULT || self.item.textcolor == DASH_COLOR_CLEAR) {
		color = self.labelTextField.textColor;
		[color getRed:&r green:&g blue:&b alpha:&a];
		color = [UIColor colorWithRed:r green:g blue:b alpha:a];
	} else {
		color = UIColorFromRGB(self.item.textcolor);
	}
	[self.textColorButton setTitle:nil forState:UIControlStateNormal];
	[self.textColorButton setFillColor:color];
	
	/* text size */
	self.textSizeDisplayValues = [NSMutableArray new];
	[self.textSizeDisplayValues addObject:@"Small"];
	[self.textSizeDisplayValues addObject:@"Medium"];
	[self.textSizeDisplayValues addObject:@"Large"];
	if (self.item.textsize >= 1 && self.item.textsize <= 3) {
		self.textSizeLabel.text = self.textSizeDisplayValues[self.item.textsize - 1];
	} else {
		self.textSizeLabel.text = self.textSizeDisplayValues[1]; // default medium
	}
	
	/* background color */
	if (self.item.background == DASH_COLOR_OS_DEFAULT || self.item.background == DASH_COLOR_CLEAR) {
		color = UIColorFromRGB(DASH_DEFAULT_CELL_COLOR);
	} else {
		color = UIColorFromRGB(self.item.background);
	}
	[self.backgroundColorButton setTitle:nil forState:UIControlStateNormal];
	[self.backgroundColorButton setFillColor:color];

}

#pragma mark - click handler

-(void)onPosButtonClicked {
	NSMutableArray *posDisplayValues = [NSMutableArray new];
	if ([self.item isKindOfClass:[DashGroupItem class]]) {
		if (self.selGroupIdx >= 0) {
			int i;
			for(i = 0; i < self.dashboard.groups.count; i++) {
				[posDisplayValues addObject:[NSString stringWithFormat:@"%d - %@",(i + 1),self.dashboard.groups[i].label ? self.dashboard.groups[i].label : @""]];
			}
			[posDisplayValues addObject:[@(i + 1) stringValue]];
		}
	} else {
		if (self.selGroupIdx >= 0) {
			DashGroupItem *g = self.dashboard.groups[self.selGroupIdx];
			NSArray<DashItem *> *items = [self.dashboard.groupItems objectForKey:@(g.id_)];
			int i;
			for(i = 0; i < items.count; i++) {
				[posDisplayValues addObject:[NSString stringWithFormat:@"%d - %@",(i + 1),items[i].label ? items[i].label : @""]];
			}
			[posDisplayValues addObject:[@(i + 1) stringValue]];
		}
	}
	if (posDisplayValues.count > 0) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Set Position:" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
		for(NSString* s in posDisplayValues) {
			[alert addAction:[UIAlertAction actionWithTitle:s style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			}]];
		}
		
		[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		}]];
		
		[alert setModalPresentationStyle:UIModalPresentationPopover];
		alert.popoverPresentationController.sourceView = self.posDropDownButton;
		alert.popoverPresentationController.sourceRect = self.posDropDownButton.bounds;
		[self presentViewController:alert animated:TRUE completion:nil];
	}
}

-(void)onGroupButtonClicked {
	NSMutableArray *posDisplayValues = [NSMutableArray new];
	if (self.selGroupIdx >= 0) {
		for(int i = 0; i < self.dashboard.groups.count; i++) {
			[posDisplayValues addObject:[NSString stringWithFormat:@"%d - %@",(i + 1),self.dashboard.groups[i].label ? self.dashboard.groups[i].label : @""]];
		}
	}
	if (posDisplayValues.count > 0) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Set Group:" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
		for(NSString* s in posDisplayValues) {
			[alert addAction:[UIAlertAction actionWithTitle:s style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			}]];
		}
		
		[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		}]];
		
		[alert setModalPresentationStyle:UIModalPresentationPopover];
		alert.popoverPresentationController.sourceView = self.groupDropDownButon;
		alert.popoverPresentationController.sourceRect = self.groupDropDownButon.bounds;
		[self presentViewController:alert animated:TRUE completion:nil];
	}
}

-(void)onTextSizeButtonClicked {
}

#pragma mark - helper

/* returns the items's group pos or the item's pos within the group (depends on groupPos) */
-(int)getPosOfItem:(DashItem *)item groupPos:(BOOL)groupPos {
	int pos = -1;
	DashGroupItem *g;
	for(int i = 0; i < self.dashboard.groups.count; i++) {
		g = self.dashboard.groups[i];
		if (item.id_ == g.id_) {
			pos = i;
			break;
		} else {
			NSArray<DashItem *> *items = [self.dashboard.groupItems objectForKey:@(g.id_)];
			for(int j = 0; j < items.count; j++) {
				if (items[j].id_ == item.id_) {
					pos = (groupPos ? i : j);
					break;
				}
			}
		}
	}
	return pos;
}

-(int)getNoOfItemsInGroup:(int)groupIdx {
	int n = 0;
	if (groupIdx >= 0 && groupIdx < self.dashboard.groups.count) {
		n = (int) [self.dashboard.groupItems objectForKey:@(self.dashboard.groups[groupIdx].id_)].count;
	}
	return n;
}

@end
