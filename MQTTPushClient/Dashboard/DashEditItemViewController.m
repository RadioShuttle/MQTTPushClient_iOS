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
#import "DashUtils.h"

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
	tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTextSizeButtonClicked)];
	tapGestureRecognizer.delaysTouchesBegan = YES;
	tapGestureRecognizer.numberOfTapsRequired = 1;
	self.textSizeLabel.userInteractionEnabled = YES;
	[self.textSizeLabel addGestureRecognizer:tapGestureRecognizer];
	[self.textSizeDropDownButton addTarget:self action:@selector(onTextSizeButtonClicked) forControlEvents:UIControlEventTouchUpInside];
	
	/* 2. background section */
	
	/* background color */
	if (self.item.background == DASH_COLOR_OS_DEFAULT || self.item.background == DASH_COLOR_CLEAR) {
		color = UIColorFromRGB(DASH_DEFAULT_CELL_COLOR);
	} else {
		color = UIColorFromRGB(self.item.background);
	}
	[self.backgroundColorButton setTitle:nil forState:UIControlStateNormal];
	[self.backgroundColorButton setFillColor:color];
	
	/* background image */
	UIImage *highlightColorImg = [DashUtils imageWithColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.5f]];
	[self.backgroundImageButton setBackgroundImage:highlightColorImg forState:UIControlStateHighlighted];
	[self.backgroundImageButton addTarget:self action:@selector(onBackgroundImageButtonClicked) forControlEvents:UIControlEventTouchUpInside];

	UIImage *backgroundImage = [DashUtils loadImageResource:self.item.background_uri userDataDir:self.dashboard.account.cacheURL];
	[self setBackgroundImage:backgroundImage];
}

-(void)setBackgroundImage:(UIImage *)backgroundImage {
	[self.backgroundImageButton setBackgroundColor:self.backgroundColorButton.fillColor];
	if (backgroundImage) {
		[self.backgroundImageButton setTitle:nil forState:UIControlStateNormal];
		[[self.backgroundImageButton imageView] setContentMode: UIViewContentModeScaleAspectFit];
		[self.backgroundImageButton setImage:backgroundImage forState:UIControlStateNormal];
		self.backgroundImageButton.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
	} else {
		[self.backgroundImageButton setTitle:@"None" forState:UIControlStateNormal];
	}

	UIColor *color;
	CGFloat a,r,g,b;
	if (self.item.textcolor == DASH_COLOR_OS_DEFAULT || self.item.textcolor == DASH_COLOR_CLEAR) {
		color = self.labelTextField.textColor;
		[color getRed:&r green:&g blue:&b alpha:&a];
		color = [UIColor colorWithRed:r green:g blue:b alpha:a];
	} else {
		color = UIColorFromRGB(self.item.textcolor);
	}

	[self.backgroundImageButton setTitleColor:color forState:UIControlStateNormal];
}

#pragma mark - click handler
-(void)onBackgroundImageButtonClicked {
	//TODO: open image chooser
}

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
		for(int i = 0; i < posDisplayValues.count; i++) {
			[alert addAction:[UIAlertAction actionWithTitle:posDisplayValues[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				self.selPosIdx = i;
				self.posLabel.text = [@(self.selPosIdx + 1) stringValue];
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
		for(int i = 0; i < posDisplayValues.count; i++) {
			[alert addAction:[UIAlertAction actionWithTitle:posDisplayValues[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				if (self.selGroupIdx != i) {
					self.selGroupIdx = i;
					self.groupLabel.text = self.dashboard.groups[i].label;
					self.selPosIdx = [self getNoOfItemsInGroup:i]; // last position in new group
					self.posLabel.text = [@(self.selPosIdx + 1) stringValue];
				}
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
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Set Text Size:" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	for(NSString *s in self.textSizeDisplayValues) {
		[alert addAction:[UIAlertAction actionWithTitle:s style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {self.textSizeLabel.text = s;
		}]];
	}
	
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[alert setModalPresentationStyle:UIModalPresentationPopover];
	alert.popoverPresentationController.sourceView = self.textSizeDropDownButton;
	alert.popoverPresentationController.sourceRect = self.textSizeDropDownButton.bounds;
	[self presentViewController:alert animated:TRUE completion:nil];

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
