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
#import "Utils.h"
#import "DashEditItemViewController.h"
#import "DashEditorOptionTableViewCell.h"


@class OptionListHandler;
@interface DashEditItemViewController ()
@property NSMutableArray<NSString *> *inputTypeDisplayValues;
@property OptionListHandler *optionListHandler;
@end

@interface OptionListHandler : NSObject <UITableViewDataSource, UITableViewDelegate>
@property DashOptionItem *item;
@property (weak) DashEditItemViewController *vc;
@end

@implementation DashEditItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
	/* add prefix to title */
	NSString *prefix = (self.mode == Add ? @"Add" : @"Edit");
	self.navigationItem.title = [NSString stringWithFormat:@"%@ %@", prefix,self.navigationItem.title];
	self.orgItem = [self.item copy];
	
	self.tableView.separatorColor = [UIColor clearColor];
	self.tableView.allowsSelection = NO;
	
	/* 1. General section */

	/* label */
	self.labelTextField.text = self.item.label;
	self.labelDefaultColor = self.labelTextField.textColor;
	
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
	[self.textColorButton setTitle:nil forState:UIControlStateNormal];
	[self.textColorButton addTarget:self action:@selector(onTextColorButtonClicked) forControlEvents:UIControlEventTouchUpInside];
	[self onColorChanged:self.textColorButton color:self.item.textcolor];
	
	/* text size */
	if (self.item.textsize >= 1 && self.item.textsize <= 3) {
		self.textSizeSegmentedCtrl.selectedSegmentIndex = self.item.textsize - 1;
	} else {
		self.textSizeSegmentedCtrl.selectedSegmentIndex = 1; // default medium
	}
	
	/* 2. background section */
	
	/* background color */
	[self.backgroundColorButton setTitle:nil forState:UIControlStateNormal];
	[self.backgroundColorButton addTarget:self action:@selector(onBackgroundColorButtonClicked) forControlEvents:UIControlEventTouchUpInside];
	[self onColorChanged:self.backgroundColorButton color:self.item.background];
	
	/* background image */
	UIImage *highlightColorImg = [DashUtils imageWithColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.5f]];
	[self.backgroundImageButton setBackgroundImage:highlightColorImg forState:UIControlStateHighlighted];
	[[self.backgroundImageButton imageView] setContentMode: UIViewContentModeScaleAspectFit];
	self.backgroundImageButton.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
	[self.backgroundImageButton addTarget:self action:@selector(onBackgroundImageButtonClicked) forControlEvents:UIControlEventTouchUpInside];
	[self onImageSelected:self.backgroundImageButton imageURI:self.item.background_uri];

	/* 3. Subscribe section */
	
	self.topicSubTextField.text = self.item.topic_s;
	[self.filterSciptButton addTarget:self action:@selector(onFilterScriptButtonClicked) forControlEvents:UIControlEventTouchUpInside];
	[self onFilterScriptContentUpdated:self.item.script_f];
	[self.filterSciptModifiedLabel setTextColor:UIColorFromRGB(DASH_COLOR_RED)]; //TODO: dark mode

	/* 4. Publish section */
	
	self.topicPubTextField.text = self.item.topic_p;
	self.retainSwitch.on = self.item.retain_;
	
	/* input type */
	if ([self.item isKindOfClass:[DashTextItem class]]) {
		DashTextItem *textItem = (DashTextItem *) self.item;
		if (textItem.inputtype >= 0 && textItem.inputtype < 2) {
			self.inputTypeSegmentedCtrl.selectedSegmentIndex = textItem.inputtype;
		} else {
			self.inputTypeSegmentedCtrl.selectedSegmentIndex = 0; // default text
		}
	}

	/* output script button */
	[self.outputSciptButton addTarget:self action:@selector(onOutputScriptButtonClicked) forControlEvents:UIControlEventTouchUpInside];
	[self onOutputScriptContentUpdated:self.item.script_p];
	[self.outputSciptModifiedLabel setTextColor:UIColorFromRGB(DASH_COLOR_RED)]; //TODO: dark mode

	/* Option List */
	if ([self.item isKindOfClass:[DashOptionItem class]]) {
		self.optionListHandler = [OptionListHandler new];
		self.optionListHandler.item = (DashOptionItem *) self.item;
		self.optionListHandler.vc = self;
		self.optionListAddButton.hidden = YES;
		[self.optionListAddButton addTarget:self action:@selector(onOptionListAddButtonClicked) forControlEvents:UIControlEventTouchUpInside];
		self.optionListTableView.allowsSelectionDuringEditing = YES;
		// [self onOptionListSizeChanged];
		[self.optionListEditButton addTarget:self action:@selector(onOptionListEditButtonClicked) forControlEvents:UIControlEventTouchUpInside];
		self.optionListTableView.dataSource = self.optionListHandler;
		self.optionListTableView.delegate = self.optionListHandler;
	}
	
}

#pragma mark - click handler
-(void)onOptionListEditButtonClicked {
	if (self.optionListTableView.isEditing) {
		[self.optionListEditButton setTitle:@"Edit" forState:UIControlStateNormal];
		self.optionListAddButton.hidden = YES;
	} else {
		[self.optionListEditButton setTitle:@"Done" forState:UIControlStateNormal];
		self.optionListAddButton.hidden = NO;
	}
	[self.optionListTableView setEditing:!self.optionListTableView.isEditing];
}

-(void)onOptionListSizeChanged {
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
}

-(void)onOptionListAddButtonClicked {
	//TODO: open add dialog
	DashOptionListItem *li = [DashOptionListItem new];
	li.value = @"uk"; //TODO: remove test code
	li.displayValue = @"United Kingdom";
	if (![self.optionListHandler.item.optionList isKindOfClass:[NSMutableArray class]]) {
		self.optionListHandler.item = [self.optionListHandler.item.optionList mutableCopy];
	}
	[((NSMutableArray *) self.optionListHandler.item.optionList) addObject:li];
	NSMutableArray *indexPathArr = [NSMutableArray new];
	[indexPathArr addObject:[NSIndexPath indexPathForRow:(self.optionListHandler.item.optionList.count - 1) inSection:0]];
	[self.optionListTableView insertRowsAtIndexPaths:indexPathArr withRowAnimation:YES];
	[self onOptionListSizeChanged];
}

-(void)onOptionListEditItemClicked:(NSIndexPath *)indexPath {
	DashOptionListItem *li = ((DashOptionItem *) self.item).optionList[indexPath.row];
	NSLog(@"Edit option item: %@", li.value);
	//TODO: open edit option list item dialog
}

-(void)onBackgroundImageButtonClicked {
	//TODO: open image chooser
	[self onImageSelected:self.backgroundImageButton imageURI:@"res://internal/lock_open"];  //TODO: remove test code
}

-(void)onTextColorButtonClicked {
	//TODO: open color chooser
	[self onColorChanged:self.textColorButton color:DASH_COLOR_RED ]; //TODO: remove test code
}

-(void)onBackgroundColorButtonClicked {
	//TODO: open color chooser
	[self onColorChanged:self.backgroundColorButton color:DASH_COLOR_YELLOW ]; //TODO: remove test code

}

-(void)onFilterScriptButtonClicked {
	//TODO: open script editor
	[self onFilterScriptContentUpdated:@"var i = 0;"];  //TODO: remove test code
}

-(void)onOutputScriptButtonClicked {
	//TODO: open script editor
	[self onOutputScriptContentUpdated:@"var i = 0;"];  //TODO: remove test code
}

-(void)onFilterScriptContentUpdated:(NSString *)content {
	self.filterSciptModifiedLabel.hidden = [self.orgItem.script_f isEqual:content];
	self.item.script_f = content;
	if ([Utils isEmpty:content]) {
		[self.filterSciptButton setTitle:@"Add" forState:UIControlStateNormal];
	} else {
		[self.filterSciptButton setTitle:@"Edit" forState:UIControlStateNormal];
	}
	
}

-(void)onOutputScriptContentUpdated:(NSString *)content {
	self.outputSciptModifiedLabel.hidden = [self.orgItem.script_p isEqual:content];
	self.item.script_p = content;
	if ([Utils isEmpty:content]) {
		[self.outputSciptButton setTitle:@"Add" forState:UIControlStateNormal];
	} else {
		[self.outputSciptButton setTitle:@"Edit" forState:UIControlStateNormal];
	}
}

-(void)onImageSelected:(UIButton *)src imageURI:(NSString *)imageURI {
	UIImage *image = nil;
	if (imageURI) {
		/* ignonre button tint color for background images -> set renderingModeAlwaysTemplate*/
		BOOL mode = (src != self.backgroundImageButton);
		image = [DashUtils loadImageResource:imageURI userDataDir:self.dashboard.account.cacheURL renderingModeAlwaysTemplate:mode];
	}
	if (image) {
		[src setTitle:nil forState:UIControlStateNormal];
		[src setImage:image forState:UIControlStateNormal];
		
		if (src != self.backgroundImageButton) {
			//TODO: tint button images (switch)
			/* tint background internal images with label default color*/
			/*
			if ([DashUtils isInternalResource:imageURI]) {
				[src setTintColor:self.labelDefaultColor];
			} else {
				// [src setTintColor:nil];
				[src setTintColor:self.labelDefaultColor]; //TODO: raus
			}
			 */
		}
	} else {
		[src setImage:nil forState:UIControlStateNormal];
		[src setTitle:@"None" forState:UIControlStateNormal];
	}
}

-(void)onColorChanged:(DashCircleViewButton *)src color:(uint64_t)color {
	UIColor *uicolor;
	CGFloat a,r,g,b;
	if (color == DASH_COLOR_OS_DEFAULT || color == DASH_COLOR_CLEAR) {
		if (src == self.textColorButton) {
			uicolor = self.labelDefaultColor; // use label color as default color
		} else {
			uicolor = UIColorFromRGB(DASH_DEFAULT_CELL_COLOR); //TODO: default color
		}
		[uicolor getRed:&r green:&g blue:&b alpha:&a]; // convert cs
		uicolor = [UIColor colorWithRed:r green:g blue:b alpha:a];
	} else {
		uicolor = UIColorFromRGB(color);
	}
	[src setFillColor:uicolor];
	[src setNeedsDisplay];
	
	/* update related views */
	if (src == self.textColorButton) {
		[self.backgroundImageButton setTitleColor:uicolor forState:UIControlStateNormal];
	} else if (src == self.backgroundColorButton) {
		[self.backgroundImageButton setBackgroundColor:uicolor];
	}
	

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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.item isKindOfClass:[DashOptionItem class]] && indexPath.section == 2 && indexPath.row == 1) {
		CGFloat th = 44 * ((DashOptionItem *) self.item).optionList.count;
		return th == 0 ? 44 : th;
	}
	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

@end

@implementation OptionListHandler
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
	DashEditorOptionTableViewCell *cell = (DashEditorOptionTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"optionListItem1"];
	DashOptionListItem *li = self.item.optionList[indexPath.row];
	NSString *p1 = li.value;
	NSString *p2 = li.displayValue;
	p1 = p1 ? p1 : @"";
	p2 = p2 ? p2 : @"";

	NSString *msg = [NSString stringWithFormat:@"%@ - %@",p1,p2];
	cell.label.text = msg;
	if (![Utils isEmpty:li.imageURI]) {
		UIImage *img = [DashUtils loadImageResource:li.imageURI userDataDir:self.vc.dashboard.account.cacheURL];
		[cell.optionImageView setImage:img];
	} else {
		[cell.optionImageView setImage:nil];
	}
	
	return cell;
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.item.optionList.count;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	DashOptionListItem *tmp = self.item.optionList[sourceIndexPath.row];
	if (![self.item.optionList isKindOfClass:[NSMutableArray class]]) {
		self.item.optionList = [self.item.optionList mutableCopy];
	}
	
	NSMutableArray *m = (NSMutableArray *) self.item.optionList;
	[m removeObjectAtIndex:sourceIndexPath.row];
	[m insertObject:tmp atIndex:destinationIndexPath.row];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

	if (![self.item.optionList isKindOfClass:[NSMutableArray class]]) {
		self.item.optionList = [self.item.optionList mutableCopy];
	}

	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSMutableArray *m = (NSMutableArray *) self.item.optionList;
		[m removeObjectAtIndex:indexPath.row];
		NSMutableArray *a = [NSMutableArray new];
		[a addObject:indexPath];
		[self.vc.optionListTableView deleteRowsAtIndexPaths:a withRowAnimation:YES];
		[self.vc onOptionListSizeChanged];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.vc.optionListTableView.isEditing) {
		[self.vc onOptionListEditItemClicked:indexPath];
	}
}

@end


