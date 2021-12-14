/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashEditOptionViewController.h"
#import "DashUtils.h"
#import "Utils.h"
#import "DashConsts.h"
#import "DashImageChooserTab.h"

@interface DashEditOptionViewController ()

@end

@implementation DashEditOptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	/* add prefix to title */
	NSString *prefix = (self.mode == Edit ? @"Edit" : @"Add");
	self.navigationItem.title = [NSString stringWithFormat:@"%@ %@", prefix, self.navigationItem.title];
	if (!self.item) {
		self.item = [DashOptionListItem new];
	}
	self.editItem = [self.item copy];

	self.tableView.separatorColor = [UIColor clearColor];
	self.tableView.allowsSelection = NO;

	UIImage *highlightColorImg = [DashUtils imageWithColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.5f]];
	[self.imageButton setBackgroundImage:highlightColorImg forState:UIControlStateHighlighted];
	[[self.imageButton imageView] setContentMode: UIViewContentModeScaleAspectFit];
	self.imageButton.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
	[self.imageButton setTintColor:[UILabel new].textColor];
	[self.imageButton setBackgroundColor:UIColorFromRGB(DASH_DEFAULT_CELL_COLOR)]; //TODO: dark mode
	
	[self.imageButton addTarget:self action:@selector(onSelectImageButtonCLicked) forControlEvents:UIControlEventTouchUpInside];

	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPosButtonClicked)];
	tapGestureRecognizer.delaysTouchesBegan = YES;
	tapGestureRecognizer.numberOfTapsRequired = 1;
	self.posLabel.userInteractionEnabled = YES;
	[self.posLabel addGestureRecognizer:tapGestureRecognizer];
	[self.posDropDownButton addTarget:self action:@selector(onPosButtonClicked) forControlEvents:UIControlEventTouchUpInside];

	self.cancelButton.target = self;
	self.cancelButton.action = @selector(onCancelButtonClicked);
	
	self.saveButton.target = self;
	self.saveButton.action = @selector(onSaveButtonClicked);
	
	self.valueTextField.text = self.item.value;
	self.labelTextField.text = self.item.displayValue;
	if (![Utils isEmpty:self.item.imageURI]) {
		[self onImageSelected:self.item.imageURI];
	}
	self.posLabel.text = [@(self.pos + 1) stringValue];
	self.selPosIdx = self.pos;
}

-(void)onSelectImageButtonCLicked {
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Dashboard" bundle:nil];
	UITabBarController *vc = [storyboard instantiateViewControllerWithIdentifier:@"DashImageChooser"];
	
	/* Use the tab ctrl for internal images from storyboard for user images */
	DashImageChooserTab *userImagesVC = [storyboard instantiateViewControllerWithIdentifier:@"DashImageChooserTab"];
	userImagesVC.tabBarItem.title = @"User";
	NSMutableArray *vcs = [vc.viewControllers mutableCopy];
	[vcs addObject:userImagesVC];
	vc.viewControllers = vcs;
	
	/* pass args directly to tab view controllers */
	if (vc.viewControllers.count > 1) {
		if ([vc.viewControllers[0] isKindOfClass:[DashImageChooserTab class]]) {
			((DashImageChooserTab *) vc.viewControllers[0]).editor = self;
			((DashImageChooserTab *) vc.viewControllers[0]).sourceButton = self.imageButton;
			((DashImageChooserTab *) vc.viewControllers[0]).context = self.parentController.dashboard;
		}
		if ([vc.viewControllers[1] isKindOfClass:[DashImageChooserTab class]]) {
			((DashImageChooserTab *) vc.viewControllers[1]).editor = self;
			((DashImageChooserTab *) vc.viewControllers[1]).sourceButton = self.imageButton;
			((DashImageChooserTab *) vc.viewControllers[1]).context = self.parentController.dashboard;
		}
	}
	vc.hidesBottomBarWhenPushed = YES;
	
	[self.navigationController pushViewController:vc animated:YES];
}

-(void)onSaveButtonClicked {
	self.editItem.value = self.valueTextField.text;
	self.editItem.displayValue = self.labelTextField.text;
	
	[self.parentController onOptionListItemUpdated:self.mode item:self.editItem oldPos:self.pos newPos:self.selPosIdx];
	[self performSegueWithIdentifier:@"IDExitEditOption" sender:self];
}

-(void)onCancelButtonClicked {
	if ([self dataModified]) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Go back without saving?" message:@"Data has been modified." preferredStyle:UIAlertControllerStyleAlert];
		
		[alert addAction:[UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self performSegueWithIdentifier:@"IDExitEditOption" sender:self];
		}]];

		[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		}]];
		[self presentViewController:alert animated:TRUE completion:nil];
	} else {
		[self performSegueWithIdentifier:@"IDExitEditOption" sender:self];
	}
}

-(BOOL)dataModified {
	self.editItem.value = self.valueTextField.text;
	self.editItem.displayValue = self.labelTextField.text;
	return !([self.editItem isEqual:self.item] && self.pos == self.selPosIdx);
}

-(void)onPosButtonClicked {
	NSMutableArray *posDisplayValues = [NSMutableArray new];
	for(int i = 0; i < self.itemCount; i++) {
		[posDisplayValues addObject:[@(i + 1) stringValue]];
	}
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Set Position:" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	if (posDisplayValues.count > 0) {
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

-(void)onImageSelected:(NSString *)imageURI {
	self.editItem.imageURI = imageURI;
	UIImage *image = nil;
	if (imageURI) {
		image = [DashUtils loadImageResource:imageURI userDataDir:self.parentController.dashboard.account.cacheURL];
	}
	if (image) {
		[self.imageButton setTitle:nil forState:UIControlStateNormal];
		self.imageButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
		self.imageButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
		[self.imageButton setImage:image forState:UIControlStateNormal];		
	} else {
		[self.imageButton setImage:nil forState:UIControlStateNormal];
		self.imageButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		self.imageButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		[self.imageButton setTitle:@"None" forState:UIControlStateNormal];
	}
}

- (IBAction) unwindImageChooserOptionItem:(UIStoryboardSegue*)unwindSegue {
	
}


@end
