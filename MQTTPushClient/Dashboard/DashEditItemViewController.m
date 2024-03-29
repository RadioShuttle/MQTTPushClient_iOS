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
#import "MqttUtils.h"
#import "DashEditItemViewController.h"
#import "DashEditorOptionTableViewCell.h"
#import "DashEditOptionViewController.h"
#import "DashColorChooser.h"
#import "DashScriptViewController.h"
#import "DashImageChooserTab.h"
#import "NSDictionary+HelSafeAccessors.h"


@import SafariServices;

@class OptionListHandler;
@class CustomItemHandler;
@class EditOptionListResult;
@interface DashEditItemViewController ()
@property NSMutableArray<NSString *> *inputTypeDisplayValues;
@property OptionListHandler *optionListHandler;
@property CustomItemHandler *customItemHandler;
@property uint64_t dashboardVersion;
@property uint32_t saveRequestID;
@property UIActivityIndicatorView *progressBar;
@property UIColor *defaultTintColor;

@property UILabel *statusLabel;
@property NSTimer *statusMsgTimer;

@property Mode argOptionListEditMode;
@property DashOptionListItem *argOptionListItem;
@property int argOptionListPos;
@property int argOptionListItemCnt;

/* set after return of option list item editor */
@property EditOptionListResult *editOptionListResult;
@end

@interface OptionListHandler : NSObject <UITableViewDataSource, UITableViewDelegate>
@property DashOptionItem *item;
@property (weak) DashEditItemViewController *vc;
@end

@interface CustomItemHandler : NSObject <UITextViewDelegate>
@property (weak) DashEditItemViewController *vc;
- (void)keyboardNotification:(NSNotification*)notification;
@end

@interface EditOptionListResult : NSObject
@property Mode mode;
@property DashOptionListItem *item;
@property int oldPos;
@property int newPos;
@end

@implementation DashEditItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.dashboardVersion = self.parentCtrl.dashboard.localVersion;
	
	/* add prefix to title */
	NSString *prefix = (self.mode == Add ? @"Add" : @"Edit");
	self.navigationItem.title = [NSString stringWithFormat:@"%@ %@", prefix,self.navigationItem.title];
	if (self.mode == Add) {
		self.item.id_ = self.parentCtrl.dashboard.max_id + 1;
	}
	self.orgItem = [self.item copy];
	
	self.tableView.separatorColor = [UIColor clearColor];
	self.tableView.allowsSelection = NO;
	
	self.defaultTintColor = self.view.tintColor;
	
	/* 1. General section */

	/* label */
	self.labelTextField.text = self.item.label;
	self.labelDefaultColor = self.labelTextField.textColor;
	
	/* group */
	self.groupLabel.text = @" ";
	if (self.mode == Add) {
		if (self.parentCtrl.dashboard.groups.count > 0) {
			self.groupLabel.text = self.parentCtrl.dashboard.groups.lastObject.label;
			self.selGroupIdx = (int) self.parentCtrl.dashboard.groups.count - 1;
		} else {
			self.selGroupIdx = -1;
		}
	} else {
		self.selGroupIdx = [self getPosOfItem:self.item groupPos:YES];
		if (self.selGroupIdx >= 0) {
			self.groupLabel.text = self.parentCtrl.dashboard.groups[self.selGroupIdx].label;
		}
	}
	self.orgSelGroupIdx = self.selGroupIdx;
	
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onGroupButtonClicked)];
	tapGestureRecognizer.delaysTouchesBegan = YES;
	tapGestureRecognizer.numberOfTapsRequired = 1;
	self.groupLabel.userInteractionEnabled = YES;
	[self.groupLabel addGestureRecognizer:tapGestureRecognizer];
	[self.groupDropDownButon addTarget:self action:@selector(onGroupButtonClicked) forControlEvents:UIControlEventTouchUpInside];
	

	/* pos within group  */
	if ([self.item isKindOfClass:[DashGroupItem class]]) {
		if (self.mode == Add) {
			self.selPosIdx = (int) self.parentCtrl.dashboard.groups.count;
		} else {
			self.selPosIdx = [self getPosOfItem:self.item groupPos:YES];
		}
	} else {
		if (self.mode == Add) {
			self.selPosIdx = [self getNoOfItemsInGroup:(int) self.parentCtrl.dashboard.groups.count - 1];
		} else {
			self.selPosIdx = [self getPosOfItem:self.item groupPos:NO];
		}
	}
	self.posLabel.text = [@(self.selPosIdx + 1) stringValue];
	self.orgSelPosIdx = self.selPosIdx;

	tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPosButtonClicked)];
	tapGestureRecognizer.delaysTouchesBegan = YES;
	tapGestureRecognizer.numberOfTapsRequired = 1;
	self.posLabel.userInteractionEnabled = YES;
	[self.posLabel addGestureRecognizer:tapGestureRecognizer];
	[self.posDropDownButton addTarget:self action:@selector(onPosButtonClicked) forControlEvents:UIControlEventTouchUpInside];
	
	/* text color */
	[self.textColorButton setTitle:nil forState:UIControlStateNormal];
	[self.textColorButton addTarget:self action:@selector(onColorButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
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
	[self.backgroundColorButton addTarget:self action:@selector(onColorButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[self onColorChanged:self.backgroundColorButton color:self.item.background];
	
	/* background image */
	UIImage *highlightColorImg = [DashUtils imageWithColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.5f]];
	[self.backgroundImageButton setBackgroundImage:highlightColorImg forState:UIControlStateHighlighted];
	[[self.backgroundImageButton imageView] setContentMode: UIViewContentModeScaleAspectFit];
	self.backgroundImageButton.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
	[self.backgroundImageButton addTarget:self action:@selector(onSelectImageButtonCLicked:) forControlEvents:UIControlEventTouchUpInside];
	[self onImageSelected:self.backgroundImageButton imageURI:self.item.background_uri];
	

	/* 3. Subscribe section */
	
	self.topicSubTextField.text = self.item.topic_s;
	[self.filterSciptButton addTarget:self action:@selector(onFilterScriptButtonClicked) forControlEvents:UIControlEventTouchUpInside];
	[self onFilterScriptContentUpdated:self.item.script_f];
	[self.filterSciptModifiedLabel setTextColor:[UIColor colorNamed:@"Color_Script_Modified"]];

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
	[self.outputSciptModifiedLabel setTextColor:[UIColor colorNamed:@"Color_Script_Modified"]];

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
	
	/* Parameters and HTML */
	if ([self.item isKindOfClass:[DashCustomItem class]]) {
		DashCustomItem * customItem = (DashCustomItem *) self.item;
		self.paramter1TextField.text = customItem.parameter.count > 0 ? customItem.parameter[0] : nil;
		self.paramter2TextField.text = customItem.parameter.count > 1 ? customItem.parameter[1] : nil;
		self.paramter3TextField.text = customItem.parameter.count > 2 ? customItem.parameter[2] : nil;

		if ([DashUtils isHTMLResource:customItem.htmlUri]) {
			NSString *html = [DashUtils loadHTMLResource:customItem.htmlUri userDataDir:self.parentCtrl.dashboard.account.cacheURL];
			if(!html) {
				[self setStatusMessage:@"Could not load HTML resource file." clearAfterDelay:NO];
			} else {
				customItem.html = html;
				((DashCustomItem *) self.orgItem).html = html;
			}
		}
		self.htmlTextView.text = customItem.html;

		
		self.moreButtonItem.target = self;
		self.moreButtonItem.action = @selector(onMoreButtonItemClicked);
		
		self.provideHistDataSwitch.on = customItem.history;

		self.customItemHandler = [CustomItemHandler new];
		self.customItemHandler.vc = self;
		self.htmlTextView.delegate = self.customItemHandler;
		[[NSNotificationCenter defaultCenter] addObserver:self.customItemHandler selector:@selector(keyboardNotification:) name:UIKeyboardDidShowNotification object:nil];
	}
	
	/* Progress Bar/Slider */
	if ([self.item isKindOfClass:[DashSliderItem class]]) {
		DashSliderItem *sliderItem = (DashSliderItem *) self.item;
		self.rangeLBTextField.text = [@(sliderItem.range_min) stringValue];
		self.rangeUBTextField.text = [@(sliderItem.range_max) stringValue];
		self.decimalTextField.text = [@(sliderItem.decimal) stringValue];
		self.displayInPercentSwitch.on = sliderItem.percent;
		[self.progressColorButton setTitle:nil forState:UIControlStateNormal];
		[self.progressColorButton addTarget:self action:@selector(onColorButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
		[self onColorChanged:self.progressColorButton color:sliderItem.progresscolor];
	}
	
	/* Button/Switch */
	if ([self.item isKindOfClass:[DashSwitchItem class]]) {
		DashSwitchItem *switchItem = (DashSwitchItem *) self.item;
		self.switchOnValueTextField.text = switchItem.val;
		
		[self.switchOnColorButton setTitle:nil forState:UIControlStateNormal];
		[self onColorChanged:self.switchOnColorButton color:switchItem.color];
		[self.switchOnColorButton addTarget:self action:@selector(onColorButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

		[self.switchOnBackgroundColorButton setTitle:nil forState:UIControlStateNormal];
		[self onColorChanged:self.switchOnBackgroundColorButton color:switchItem.bgcolor];
		[self.switchOnBackgroundColorButton addTarget:self action:@selector(onColorButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

		[self.switchOnImageButton setBackgroundImage:highlightColorImg forState:UIControlStateHighlighted];
		[[self.switchOnImageButton imageView] setContentMode: UIViewContentModeScaleAspectFit];
		self.switchOnImageButton.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
		[self.switchOnImageButton addTarget:self action:@selector(onSelectImageButtonCLicked:) forControlEvents:UIControlEventTouchUpInside];
		[self onImageSelected:self.switchOnImageButton imageURI:switchItem.uri];
		
		self.switchOffValueTextField.text = switchItem.valOff;

		[self.switchOffColorButton setTitle:nil forState:UIControlStateNormal];
		[self onColorChanged:self.switchOffColorButton color:switchItem.colorOff];
		[self.switchOffColorButton addTarget:self action:@selector(onColorButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

		[self.switchOffBackgroundColorButton setTitle:nil forState:UIControlStateNormal];
		[self onColorChanged:self.switchOffBackgroundColorButton color:switchItem.bgcolorOff];
		[self.switchOffBackgroundColorButton addTarget:self action:@selector(onColorButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

		[self.switchOffImageButton setBackgroundImage:highlightColorImg forState:UIControlStateHighlighted];
		[[self.switchOffImageButton imageView] setContentMode: UIViewContentModeScaleAspectFit];
		self.switchOffImageButton.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
		[self.switchOffImageButton addTarget:self action:@selector(onSelectImageButtonCLicked:) forControlEvents:UIControlEventTouchUpInside];
		[self onImageSelected:self.switchOffImageButton imageURI:switchItem.uriOff];
	}
	
	/* Add status label*/
	UIBarButtonItem *tbBarButtonItem = [[UIBarButtonItem alloc] init];
	UIView *view = [[UIView alloc] init];
	view.translatesAutoresizingMaskIntoConstraints = NO;
	[tbBarButtonItem setCustomView:view];
	self.statusLabel = [[UILabel alloc] init];
	self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[view addSubview:self.statusLabel];
	[self.statusLabel.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
	[self.statusLabel.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
	[self.statusLabel.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
	[self.statusLabel.bottomAnchor constraintEqualToAnchor:view.bottomAnchor].active = YES;
	[self.statusLabel setFont:[self.statusLabel.font fontWithSize:14]];
	NSMutableArray *barItems = [NSMutableArray new];
	[barItems addObject:tbBarButtonItem];
	self.toolbarItems = barItems;
	
	/* Replace back navigation with cancel button */
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] init];
	cancelButton.title = @"Cancel";
	cancelButton.target = self;
	cancelButton.action = @selector(onCancelButtonClicked);
	self.navigationItem.leftBarButtonItem = cancelButton;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSaveRequestFinished:) name:@"ServerUpdateNotification" object:self.parentCtrl.connection];

}

-(void)onCancelButtonClicked {
	
	DashItem *currentData = [self getDashItem];
	BOOL modified = !([currentData isEqual:self.orgItem] && self.orgSelGroupIdx == self.selGroupIdx && self.orgSelPosIdx == self.selPosIdx);
	if (modified) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Go back without saving?" message:@"Data has been modified." preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self.navigationController popViewControllerAnimated:YES];
		}]];
		[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		}]];
		[self presentViewController:alert animated:YES completion:nil];

	} else {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (IBAction)onSaveButtonClicked:(id)sender {
	if (self.saveRequestID > 0) {
		[self setStatusMessage:@"A save operation is currently in progress." clearAfterDelay:YES];
		return;
	} else if (self.dashboardVersion != self.parentCtrl.dashboard.localVersion) {
		[self setStatusMessage:@"Version error. Quit the editor to update to the latest version." clearAfterDelay:NO];
		return;
	}
	
	DashItem *editedItem = [[self getDashItem] copy];
	BOOL modified = !([editedItem isEqual:self.orgItem] && self.orgSelGroupIdx == self.selGroupIdx && self.orgSelPosIdx == self.selPosIdx);
	if (!modified && self.mode == Edit) {
		[self setStatusMessage:@"Data was not modified." clearAfterDelay:YES];
	} else {

		/* validate topics */
		NSString *topicChecked;
		int step = 0;
		BOOL wildCardAllowed = !editedItem.history;
		/* check topic format */
		@try {
			topicChecked = @"Topic (sub): ";
			if (editedItem.topic_s.length > 0) {
				[MqttUtils topicValidate:editedItem.topic_s wildcardAllowed:wildCardAllowed];
			}
			step++;
			topicChecked = @"Topic (pub): ";
			if (editedItem.topic_p.length > 0) {
				[MqttUtils topicValidate:editedItem.topic_p wildcardAllowed:NO];
			}
		} @catch(NSException *ex) {
			NSMutableString *errTopic = [NSMutableString stringWithString:topicChecked];
			if (ex.reason) {
				if ([ex.reason hasPrefix:@"Wildcards are not allowed"] && step == 0 && !wildCardAllowed) {
					[errTopic appendString:@"Wildcards are not allowed, if historical data are to be provided."];
				} else {
					[errTopic appendString:ex.reason];
				}
			} else {
				[errTopic appendString:@"Invalid format."];
			}
			[self setStatusMessage:errTopic clearAfterDelay:NO];
			return;
		}
		
		/* prepare data for saving: clone dashboard */
		NSMutableArray<DashGroupItem *> *groups = [self.parentCtrl.dashboard.groups mutableCopy];
		NSMutableDictionary<NSNumber *, NSArray<DashItem *> *> *groupItems = [self.parentCtrl.dashboard.groupItems mutableCopy];
		if (!groups) { // first dashboard?
			groups = [NSMutableArray new];
			groupItems = [NSMutableDictionary new];
		}
		
		/* item values may have changed by script, so get the original item */
		for(int i = 0; i < groups.count; i++) {
			groups[i] = (DashGroupItem *) [self.parentCtrl.dashboard getUnmodifiedItemForID:groups[i].id_];
			NSMutableArray<DashItem *> *items = [[groupItems objectForKey:@(groups[i].id_)] mutableCopy];
			[groupItems setObject:items forKey:@(groups[i].id_)];
			for(int j = 0; j < items.count; j++) {
				items[j] = [self.parentCtrl.dashboard getUnmodifiedItemForID:items[j].id_];
			}
		}
		/* add new/modified item to cloned collection object */
		DashGroupItem *group;
		NSMutableArray<DashItem *> *items;
		
		if (self.mode == Add) {
			if ([editedItem isKindOfClass:[DashGroupItem class]]) {
				[groups insertObject:(DashGroupItem *) editedItem atIndex:self.selPosIdx];
				[groupItems setObject:[NSArray new] forKey:@(editedItem.id_)];
			} else {
				if (self.selGroupIdx == -1) { // first item in dashboard? add group
					group = [DashGroupItem new];
					group.id_ = editedItem.id_ + 1;
					group.label = @"New Group";
					[groups addObject:group];
					[groupItems setObject:[NSMutableArray new] forKey:@(group.id_)];
				} else {
					group = groups[self.selGroupIdx];
				}				
				items = (NSMutableArray *) [groupItems objectForKey:@(group.id_)];
				[items insertObject:editedItem atIndex:self.selPosIdx];
			}
		} else { // mode == edit
			if ([editedItem isKindOfClass:[DashGroupItem class]]) {
				if (self.orgSelPosIdx != self.selPosIdx) {
					[groups removeObjectAtIndex:self.orgSelPosIdx];
					[groups insertObject:(DashGroupItem *) editedItem atIndex:(self.orgSelPosIdx < self.selPosIdx ? self.selPosIdx - 1 : self.selPosIdx)];
				} else {
					[groups replaceObjectAtIndex:self.orgSelPosIdx withObject:(DashGroupItem *) editedItem];
				}
			} else {
				group = groups[self.orgSelGroupIdx];
				items = (NSMutableArray *) [groupItems objectForKey:@(group.id_)];
				if (self.orgSelGroupIdx == self.selGroupIdx) {
					if (self.orgSelPosIdx == self.selPosIdx) {
						[items replaceObjectAtIndex:self.selPosIdx withObject:editedItem];
					} else {
						[items removeObjectAtIndex:self.orgSelPosIdx];
						[items insertObject:editedItem atIndex:(self.orgSelPosIdx < self.selPosIdx ? self.selPosIdx - 1 : self.selPosIdx)];
					}
				} else {
					[items removeObjectAtIndex:self.orgSelPosIdx];
					group = groups[self.selGroupIdx];
					items = (NSMutableArray *) [groupItems objectForKey:@(group.id_)];
					[items insertObject:editedItem atIndex:self.selPosIdx];
				}
			}
		}
		/* prepare data to JSON */
		NSMutableDictionary *dashJson = [Dashboard itemsToJSON:groups items:groupItems];
		[dashJson setObject:@(DASHBOARD_PROTOCOL_VERSION) forKey:@"version"];
		
		/* add locked resources */
		NSMutableArray *lockedResources = [NSMutableArray new];
		for(NSString *r in self.parentCtrl.dashboard.resources) {
			if (![Utils isEmpty:r]) {
				[lockedResources addObject:r];
			}
		}
		[dashJson setObject:lockedResources forKey:@"resources"];

		NSMutableDictionary *userInfo = [NSMutableDictionary new];
		self.saveRequestID = ++self.parentCtrl.saveRequestCnt;
		[userInfo setObject:[NSNumber numberWithInt:self.saveRequestID] forKey:@"save_request"];
		
		[self.parentCtrl.connection saveDashboardForAccount:self.parentCtrl.dashboard.account json:dashJson prevVersion:self.parentCtrl.dashboard.localVersion itemID:editedItem.id_ userInfo:userInfo];
		[self showProgressBar];
	}
}

- (void)onSaveRequestFinished:(NSNotification *)notif {
	uint32_t saveRequestID = [[notif.userInfo helNumberForKey:@"save_request"] unsignedIntValue];
	if (saveRequestID > 0 && self.saveRequestID == saveRequestID) {
		self.saveRequestID = 0;
		[self hideProgressBar];
		
		if (self.parentCtrl.dashboard.account.error) {
			[self setStatusMessage:self.parentCtrl.dashboard.account.error.localizedDescription clearAfterDelay:NO];
		} else {
			BOOL versionError = [[notif.userInfo helNumberForKey:@"invalidVersion"] boolValue];
			if (versionError) {
				[self setStatusMessage:@"Version error. Quit editor to update to latest version." clearAfterDelay:NO];
			} else {
				uint64_t newVersion = [[notif.userInfo helNumberForKey:@"serverVersion"] unsignedLongLongValue];
				NSString *newDashboard = [notif.userInfo helStringForKey:@"dashboardJS"];
				if (newVersion > 0 && newDashboard) {
					[self.parentCtrl onDashboardSaved:newDashboard version:newVersion];
				}
				[self.navigationController popViewControllerAnimated:YES];
			}
		}
	}
}

-(void)setStatusMessage:(NSString *) msg clearAfterDelay:(BOOL)clearAfterDelay {
	if (self.statusMsgTimer) {
		[self.statusMsgTimer invalidate];
	}
	self.statusLabel.text = msg;
	if (clearAfterDelay) {
		self.statusMsgTimer = [NSTimer scheduledTimerWithTimeInterval:5 repeats:NO block:^(NSTimer * _Nonnull timer){self.statusLabel.text = nil; }];
	}
}

-(DashItem *)getDashItem {
	self.item.label = self.labelTextField.text;

	NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
	f.numberStyle = NSNumberFormatterDecimalStyle;
	NSNumber *num;
	
	BOOL hasTextSize = NO;
	if ([self.item isKindOfClass:[DashGroupItem class]]) {
		hasTextSize = YES;
	} else if ([self.item isKindOfClass:[DashSliderItem class]]) {
		hasTextSize = YES;
		DashSliderItem *sliderItem = (DashSliderItem *)self.item;
		num = [f numberFromString:self.rangeLBTextField.text];
		if (num) {
			sliderItem.range_min = [num doubleValue];
		} //TODO: error message if no a number?
		num = [f numberFromString:self.rangeUBTextField.text];
		if (num) {
			sliderItem.range_max = [num doubleValue];
		} //TODO: error message if no a number?
		num = [f numberFromString:self.decimalTextField.text];
		if (num) {
			sliderItem.decimal = [num intValue];
		} //TODO: error message if no a number?
		sliderItem.percent = self.displayInPercentSwitch.on;
	} else if ([self.item isKindOfClass:[DashTextItem class]]) {
		((DashTextItem *) self.item).inputtype = (int) self.inputTypeSegmentedCtrl.selectedSegmentIndex;
		hasTextSize = YES;
	} else if ([self.item isKindOfClass:[DashOptionItem class]]) {
		hasTextSize = YES;
		// DashOptionItem *optionItem = (DashOptionItem *) self.item;
	} else if ([self.item isKindOfClass:[DashSwitchItem class]]) {
		DashSwitchItem *switchItem = (DashSwitchItem *) self.item;
		switchItem.val = self.switchOnValueTextField.text;
		switchItem.valOff = self.switchOffValueTextField.text;
	} else if ([self.item isKindOfClass:[DashCustomItem class]]) {
		DashCustomItem *customItem = (DashCustomItem *) self.item;
		customItem.history = self.provideHistDataSwitch.on;
		NSMutableArray *paras = (NSMutableArray *) customItem.parameter;
		[paras removeAllObjects];
		NSString *p = self.paramter1TextField.text;
		[paras addObject:(p ? p : @"")];
		p = self.paramter2TextField.text;
		[paras addObject:(p ? p : @"")];
		p = self.paramter3TextField.text;
		[paras addObject:(p ? p : @"")];
		customItem.html = self.htmlTextView.text;
	}
	self.item.topic_p = self.topicPubTextField.text;
	self.item.topic_s = self.topicSubTextField.text;
	self.item.retain_ = self.retainSwitch.on;
	if (hasTextSize) {
		int textSize = (int) [self.textSizeSegmentedCtrl selectedSegmentIndex];
		if (self.item.textsize == 0 && textSize == 1) {
			; // default value
		} else {
			self.item.textsize = textSize + 1;
		}
	}
	
	return self.item;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSString *identifier = segue.identifier;
	if ([identifier isEqualToString:@"IDShowEditOptionListItemView"]) {
		DashEditOptionViewController *vc = segue.destinationViewController;
		vc.mode = self.argOptionListEditMode;
		vc.item = self.argOptionListItem;
		vc.pos = self.argOptionListPos;
		vc.itemCount = self.argOptionListItemCnt;
		vc.parentController = self;
	}
}

#pragma mark - click handler
-(void)onMoreButtonItemClicked {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[alert addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self onClearClicked];
	}]];
	
	[alert addAction:[UIAlertAction actionWithTitle:@"Insert Example" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self onInsertExampleClicked];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Help" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self onHelpClicked];
	}]];
	
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[alert setModalPresentationStyle:UIModalPresentationPopover];
	
	alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
	[self presentViewController:alert animated:YES completion:nil];
}

-(void)onInsertExampleClicked {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Insert Example" preferredStyle:UIAlertControllerStyleActionSheet];
	NSMutableArray *titles = [NSMutableArray new];
	[titles addObject:@"Basic HTML"];
	[titles addObject:@"Color Picker"];
	[titles addObject:@"Gauge"];
	[titles addObject:@"Clock"];
	[titles addObject:@"Light Switch With Color Picker"];
	[titles addObject:@"Thermometer"];
	[titles addObject:@"Line Graph"];
	NSMutableArray *examples = [NSMutableArray new];
	[examples addObject:@"empty"];
	[examples addObject:@"color_picker"];
	[examples addObject:@"gauge"];
	[examples addObject:@"clock"];
	[examples addObject:@"light_switch_with_color_chooser"];
	[examples addObject:@"thermometer"];
	[examples addObject:@"line_graph"];

	for(int i = 0; i < titles.count; i++) {
		[alert addAction:[UIAlertAction actionWithTitle:titles[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self insertExample:examples[i]];
		}]];
	}
	
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[alert setModalPresentationStyle:UIModalPresentationPopover];
	
	alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
	[self presentViewController:alert animated:YES completion:nil];

}

-(void)insertExample:(NSString *)resourceName {
	NSURL *fileURL = [[NSBundle mainBundle] URLForResource:resourceName withExtension:@"html"];
	NSString *resouce = [NSString stringWithContentsOfURL:fileURL
												 encoding:NSUTF8StringEncoding error:NULL];
	if (resouce.length > 0) {
		NSMutableString *t = [NSMutableString new];
		if (self.htmlTextView.text) {
			[t appendString:[self.htmlTextView.text copy]];
			if (![self.htmlTextView.text hasSuffix:@"\n"]) {
				[t appendString:@"\n"];
			}
		}
		[t appendString:resouce];
		self.htmlTextView.text = t;
		[self.customItemHandler textViewDidChange:self.htmlTextView];
	}
}

-(void)onClearClicked {
	if (![Utils isEmpty:self.htmlTextView.text]) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Clear HTML content?" preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {self.htmlTextView.text = nil; [self.customItemHandler textViewDidChange:self.htmlTextView];
		}]];
		[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		}]];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

-(void)onHelpClicked {
	[self showCustomViewHelp];
}

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
	self.argOptionListEditMode = Add;
	self.argOptionListItem = nil;
	self.argOptionListPos = (int) ((DashOptionItem *) self.item).optionList.count;
	self.argOptionListItemCnt = self.argOptionListPos;
	[self performSegueWithIdentifier:@"IDShowEditOptionListItemView" sender:self];
}

-(void)onOptionListEditItemClicked:(NSIndexPath *)indexPath {
	DashOptionListItem *item = ((DashOptionItem *) self.item).optionList[indexPath.row];
	self.argOptionListEditMode = Edit;
	self.argOptionListItem = item;
	self.argOptionListPos = (int) indexPath.row;
	self.argOptionListItemCnt = (int) ((DashOptionItem *) self.item).optionList.count;
	[self performSegueWithIdentifier:@"IDShowEditOptionListItemView" sender:self];
}

- (void)onOptionListItemUpdated:(Mode)mode item:(DashOptionListItem *)item oldPos:(int)oldPos newPos:(int)newPos {
	if (!self.tableView.window) {
		/* window must be attached to view, so update option list table a bit later in viewDidAppear */
		self.editOptionListResult = [EditOptionListResult new];
		self.editOptionListResult.mode = mode;
		self.editOptionListResult.item = item;
		self.editOptionListResult.oldPos = oldPos;
		self.editOptionListResult.newPos = newPos;
	} else {
		[self updateOptionListItemUpdated:mode item:item oldPos:oldPos newPos:newPos];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (self.editOptionListResult) {
		[self updateOptionListItemUpdated:self.editOptionListResult.mode item:self.editOptionListResult.item oldPos:self.editOptionListResult.oldPos newPos:self.editOptionListResult.newPos];
		self.editOptionListResult = nil;
	}
}

-(void)updateOptionListItemUpdated:(Mode)mode item:(DashOptionListItem *)item oldPos:(int)oldPos newPos:(int)newPos {

	DashOptionItem *optItem = (DashOptionItem *) self.item;
	if (![self.optionListHandler.item.optionList isKindOfClass:[NSMutableArray class]]) {
		self.optionListHandler.item = [self.optionListHandler.item.optionList mutableCopy];
	}
	NSMutableArray *indexPathArr = [NSMutableArray new];
	
	if (mode == Add) {
		[((NSMutableArray *) optItem.optionList) insertObject:item atIndex:newPos];
		[indexPathArr addObject:[NSIndexPath indexPathForRow:newPos inSection:0]];
		[self.optionListTableView insertRowsAtIndexPaths:indexPathArr withRowAnimation:YES];
	} else {
		if (oldPos == newPos) {
			[((NSMutableArray *) optItem.optionList) setObject:item atIndexedSubscript:(NSUInteger)newPos];
			[indexPathArr addObject:[NSIndexPath indexPathForRow:newPos inSection:0]];
			[self.optionListTableView reloadRowsAtIndexPaths:indexPathArr withRowAnimation:YES];
		} else {
			[((NSMutableArray *) optItem.optionList) removeObjectAtIndex:oldPos];
			[indexPathArr addObject:[NSIndexPath indexPathForRow:oldPos inSection:0]];
			[self.optionListTableView deleteRowsAtIndexPaths:indexPathArr withRowAnimation:YES];

			[indexPathArr removeAllObjects];
			[((NSMutableArray *) optItem.optionList) insertObject:item atIndex:newPos];
			[indexPathArr addObject:[NSIndexPath indexPathForRow:newPos inSection:0]];
			[self.optionListTableView insertRowsAtIndexPaths:indexPathArr withRowAnimation:YES];
		}
	}
	[self onOptionListSizeChanged];
}

-(void)onColorButtonClicked:(DashCircleViewButton *)src {
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Dashboard" bundle:nil];
	DashColorChooser* vc = [storyboard instantiateViewControllerWithIdentifier:@"DashColorChooser"];
	vc.parentCtrl = self;
	vc.srcButton = src;
	vc.showClearColor = (src == self.switchOnColorButton || src == self.switchOffColorButton);
	
	/* default color */
	if (src == self.textColorButton) {
		vc.defaultColor = self.labelDefaultColor; // use label color as default color
	} else if (src == self.progressColorButton) {
		vc.defaultColor = self.defaultTintColor; // use default tint color
	} else if (src == self.switchOnColorButton || src == self.switchOffColorButton) {
		vc.defaultColor = self.labelDefaultColor;
	} else {
		vc.defaultColor = [UIColor colorNamed:@"Color_Item_Background"];
	}
	CGFloat r,g,b,a;
	[vc.defaultColor getRed:&r green:&g blue:&b alpha:&a]; // convert cs
	vc.defaultColor = [UIColor colorWithRed:r green:g blue:b alpha:a];

	UINavigationController *nc =
	[[UINavigationController alloc] initWithRootViewController:vc];
	
	nc.modalPresentationStyle = UIModalPresentationPopover;
	
	nc.popoverPresentationController.sourceView = src;
	nc.popoverPresentationController.sourceRect = src.bounds;
	
	[self presentViewController:nc animated:YES completion:nil];
}

-(void)onSelectImageButtonCLicked:(UIButton *)src {
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
			((DashImageChooserTab *) vc.viewControllers[0]).sourceButton = src;
			((DashImageChooserTab *) vc.viewControllers[0]).context = self.parentCtrl.dashboard;
		}
		if ([vc.viewControllers[1] isKindOfClass:[DashImageChooserTab class]]) {
			((DashImageChooserTab *) vc.viewControllers[1]).editor = self;
			((DashImageChooserTab *) vc.viewControllers[1]).sourceButton = src;
			((DashImageChooserTab *) vc.viewControllers[1]).context = self.parentCtrl.dashboard;
		}
	}
	vc.hidesBottomBarWhenPushed = YES;
	
	[self.navigationController pushViewController:vc animated:YES];
}

-(void)onFilterScriptButtonClicked {
	[self openScriptEditor:YES]; //open editor in filter script mode
}

-(void)onOutputScriptButtonClicked {
	[self openScriptEditor:NO]; //open editor in output script mode
}

-(void)openScriptEditor:(BOOL)filterScriptMode {
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Dashboard" bundle:nil];
	DashScriptViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"DashScriptEditor"];

	vc.filterScriptMode = filterScriptMode;
	vc.parentCtrl = self;
	
	[self.navigationController pushViewController:vc animated:YES];

}

-(void)onFilterScriptContentUpdated:(NSString *)content {
	self.filterSciptModifiedLabel.hidden = [Utils areEqual:self.orgItem.script_f s2:content];
	self.item.script_f = content;
	if ([Utils isEmpty:content]) {
		[self.filterSciptButton setTitle:@"Add" forState:UIControlStateNormal];
	} else {
		[self.filterSciptButton setTitle:@"Edit" forState:UIControlStateNormal];
	}
	
}

-(void)onOutputScriptContentUpdated:(NSString *)content {
	self.outputSciptModifiedLabel.hidden = [Utils areEqual:self.orgItem.script_p s2:content];
	self.item.script_p = content;
	if ([Utils isEmpty:content]) {
		[self.outputSciptButton setTitle:@"Add" forState:UIControlStateNormal];
	} else {
		[self.outputSciptButton setTitle:@"Edit" forState:UIControlStateNormal];
	}
}

-(void)onImageSelected:(UIButton *)src imageURI:(NSString *)imageURI {
	if (src == self.backgroundImageButton) {
		self.item.background_uri = imageURI;
	} else if (src == self.switchOnImageButton) {
		((DashSwitchItem *) self.item).uri = imageURI;
	} else if (src == self.switchOffImageButton) {
		((DashSwitchItem *) self.item).uriOff = imageURI;
	}
	
	UIImage *image = nil;
	BOOL showImageErr = NO;
	if (![Utils isEmpty:imageURI]) {
		image = [DashUtils loadImageResource:imageURI userDataDir:self.parentCtrl.dashboard.account.cacheURL];
		showImageErr = !image;
		
		if (src == self.switchOnImageButton) {
			if (self.switchOnColorButton.clearColor) {
				if ([DashUtils isInternalResource:imageURI]) {
					[src setTintColor:self.labelDefaultColor];
					image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
				}
			} else {
				image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			}
		} else if (src == self.switchOffImageButton) {
			if (self.switchOffColorButton.clearColor) {
				if ([DashUtils isInternalResource:imageURI]) {
					[src setTintColor:self.labelDefaultColor];
					image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
				}
			} else {
				image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			}
		}
	}
	
	if (src == self.backgroundImageButton) {
		self.backgroundImageErrorLabel.hidden = !showImageErr;
	} else if (src == self.switchOnImageButton) {
		self.switchOnImageErrorLabel.hidden = !showImageErr;
	} else if (src == self.switchOffImageButton) {
		self.switchOffImageErrorLabel.hidden = !showImageErr;
	}
	
	if (image) {
		[src setTitle:nil forState:UIControlStateNormal];
		src.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
		src.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
		[src setImage:image forState:UIControlStateNormal];
	} else {
		src.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		src.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		[src setImage:nil forState:UIControlStateNormal];
		[src setTitle:@"None" forState:UIControlStateNormal];
	}
	
}

-(void)onColorChanged:(DashCircleViewButton *)src color:(int64_t)color {
	UIColor *uicolor;
	CGFloat a,r,g,b;
	if (color == DASH_COLOR_CLEAR) {
		uicolor = [UIColor clearColor];
		src.clearColor = YES;
		[uicolor getRed:&r green:&g blue:&b alpha:&a]; // convert cs
		uicolor = [UIColor colorWithRed:r green:g blue:b alpha:a];
	} else if (color == DASH_COLOR_OS_DEFAULT) {
		if (src == self.textColorButton) {
			uicolor = self.labelDefaultColor; // use label color as default color
		} else if (src == self.progressColorButton) {
			uicolor = self.defaultTintColor; // use default tint color
		} else if (src == self.switchOnColorButton || src == self.switchOffColorButton) {
			uicolor = self.labelDefaultColor;
		} else {
			uicolor = [UIColor colorNamed:@"Color_Item_Background"];
		}
		[uicolor getRed:&r green:&g blue:&b alpha:&a]; // convert cs
		uicolor = [UIColor colorWithRed:r green:g blue:b alpha:a];
		src.clearColor = NO;
	} else {
		uicolor = UIColorFromRGB(color);
		src.clearColor = NO;
	}
	[src setFillColor:uicolor];
	[src setNeedsDisplay];
	
	/* update item */
	if (src == self.textColorButton) {
		self.item.textcolor = color;
	} else if (src == self.backgroundColorButton) {
		self.item.background = color;
	} else if (src == self.progressColorButton) {
		DashSliderItem *sliderItem = (DashSliderItem *) self.item;
		sliderItem.progresscolor = color;
	} else if (src == self.switchOnColorButton) {
		DashSwitchItem *switchItem = (DashSwitchItem *) self.item;
		switchItem.color = color;
	} else if (src == self.switchOffColorButton) {
		DashSwitchItem *switchItem = (DashSwitchItem *) self.item;
		switchItem.colorOff = color;
	} else if (src == self.switchOnBackgroundColorButton) {
		DashSwitchItem *switchItem = (DashSwitchItem *) self.item;
		switchItem.bgcolor = color;
	} else if (src == self.switchOffBackgroundColorButton) {
		DashSwitchItem *switchItem = (DashSwitchItem *) self.item;
		switchItem.bgcolorOff = color;
	}
	
	/* update related views */
	if (src == self.textColorButton) {
		[self.backgroundImageButton setTitleColor:uicolor forState:UIControlStateNormal];
	} else if (src == self.backgroundColorButton) {
		[self.backgroundImageButton setBackgroundColor:uicolor];
	} else if (src == self.switchOnColorButton) {
		UIColor *titleColor;
		UIColor *imageColor;
		if (src.clearColor) {
			titleColor = self.labelDefaultColor;
			imageColor = nil;
		} else {
			titleColor = uicolor;
			imageColor = uicolor;
		}
		[self.switchOnImageButton setTitleColor:titleColor forState:UIControlStateNormal];
		if (imageColor) {
			if (self.switchOnImageButton.imageView.image.renderingMode != UIImageRenderingModeAlwaysTemplate) {
				self.switchOnImageButton.imageView.image = [self.switchOnImageButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			}
			[self.switchOnImageButton setTintColor:imageColor];
		} else {
			if (self.switchOnImageButton.imageView.image.renderingMode != UIImageRenderingModeAlwaysOriginal) {
				self.switchOnImageButton.imageView.image = [self.switchOnImageButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
			}
			// [self.switchOnImageButton setTintColor:nil];
		}

	} else if (src == self.switchOffColorButton) {
		UIColor *titleColor;
		UIColor *imageColor;
		if (src.clearColor) {
			titleColor = self.labelDefaultColor;
			imageColor = nil;
		} else {
			titleColor = uicolor;
			imageColor = uicolor;
		}
		[self.switchOffImageButton setTitleColor:titleColor forState:UIControlStateNormal];
		if (imageColor) {
			if (self.switchOffImageButton.imageView.image.renderingMode != UIImageRenderingModeAlwaysTemplate) {
				self.switchOffImageButton.imageView.image = [self.switchOffImageButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			}
			[self.switchOffImageButton setTintColor:imageColor];
		} else {
			if (self.switchOffImageButton.imageView.image.renderingMode != UIImageRenderingModeAlwaysOriginal) {
				self.switchOffImageButton.imageView.image = [self.switchOffImageButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
			}
			// [self.switchOnImageButton setTintColor:nil];
		}
	} else if (src == self.switchOnBackgroundColorButton) {
		[self.switchOnImageButton setBackgroundColor:uicolor];
	} else if (src == self.switchOffBackgroundColorButton) {
		[self.switchOffImageButton setBackgroundColor:uicolor];
	}
}

-(void)onPosButtonClicked {
	NSMutableArray *posDisplayValues = [NSMutableArray new];
	if ([self.item isKindOfClass:[DashGroupItem class]]) {
		if (self.selGroupIdx >= 0) {
			int i;
			for(i = 0; i < self.parentCtrl.dashboard.groups.count; i++) {
				[posDisplayValues addObject:[NSString stringWithFormat:@"%d - %@",(i + 1),self.parentCtrl.dashboard.groups[i].label ? self.parentCtrl.dashboard.groups[i].label : @""]];
			}
			[posDisplayValues addObject:[@(i + 1) stringValue]];
		}
	} else {
		if (self.selGroupIdx >= 0) {
			DashGroupItem *g = self.parentCtrl.dashboard.groups[self.selGroupIdx];
			NSArray<DashItem *> *items = [self.parentCtrl.dashboard.groupItems objectForKey:@(g.id_)];
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
		[self presentViewController:alert animated:YES completion:nil];
	}
}

-(void)onGroupButtonClicked {
	NSMutableArray *posDisplayValues = [NSMutableArray new];
	if (self.selGroupIdx >= 0) {
		for(int i = 0; i < self.parentCtrl.dashboard.groups.count; i++) {
			[posDisplayValues addObject:[NSString stringWithFormat:@"%d - %@",(i + 1),self.parentCtrl.dashboard.groups[i].label ? self.parentCtrl.dashboard.groups[i].label : @""]];
		}
	}
	if (posDisplayValues.count > 0) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Set Group:" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
		for(int i = 0; i < posDisplayValues.count; i++) {
			[alert addAction:[UIAlertAction actionWithTitle:posDisplayValues[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				if (self.selGroupIdx != i) {
					self.selGroupIdx = i;
					self.groupLabel.text = self.parentCtrl.dashboard.groups[i].label;
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
		[self presentViewController:alert animated:YES completion:nil];
	}
}

- (void)showCustomViewHelp {
	NSString *urlString = @"https://help.radioshuttle.de/mqttapp/1.0/en/dashboard_scripts.html#customviewHTML?client=iOS";
	if ([[[NSLocale preferredLanguages] firstObject] hasPrefix:@"de"]) {
		urlString = @"https://help.radioshuttle.de/mqttapp/1.0/de/dashboard_scripts.html#customviewHTML?client=iOS";
	}
	NSURL *url = [NSURL URLWithString:urlString];
	SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
	if (@available(iOS 13.0, *)) {
		safariViewController.preferredBarTintColor = [UIColor systemBackgroundColor];
		safariViewController.preferredControlTintColor = self.view.tintColor;
	}
	[self presentViewController:safariViewController animated:YES completion:^{}];
	
}

#pragma mark - helper

/* returns the items's group pos or the item's pos within the group (depends on groupPos) */
-(int)getPosOfItem:(DashItem *)item groupPos:(BOOL)groupPos {
	int pos = -1;
	DashGroupItem *g;
	for(int i = 0; i < self.parentCtrl.dashboard.groups.count; i++) {
		g = self.parentCtrl.dashboard.groups[i];
		if (item.id_ == g.id_) {
			pos = i;
			break;
		} else {
			NSArray<DashItem *> *items = [self.parentCtrl.dashboard.groupItems objectForKey:@(g.id_)];
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
	if (groupIdx >= 0 && groupIdx < self.parentCtrl.dashboard.groups.count) {
		n = (int) [self.parentCtrl.dashboard.groupItems objectForKey:@(self.parentCtrl.dashboard.groups[groupIdx].id_)].count;
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

- (IBAction) unwindEditOptionListItem:(UIStoryboardSegue*)unwindSegue {
	
}

- (IBAction) unwindColorChooser:(UIStoryboardSegue*)unwindSegue {
	
}

- (IBAction) unwindImageChooser:(UIStoryboardSegue*)unwindSegue {
	
}

- (void)showProgressBar {
	if (!self.progressBar) {
		self.progressBar = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
		self.progressBar.color = [UILabel new].textColor;
		self.progressBar.translatesAutoresizingMaskIntoConstraints = NO;
		[self.view addSubview:self.progressBar];
		[self.progressBar startAnimating];
		
		[self.progressBar.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:0.0].active = YES;
		[self.progressBar.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:0.0].active = YES;
		
		[self.view bringSubviewToFront:self.progressBar];
	}
}

- (void)hideProgressBar {
	if (self.progressBar) {
		[self.progressBar stopAnimating];
		[self.progressBar removeFromSuperview];
		self.progressBar = nil;
	}
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
	[cell.optionImageView setTintColor:self.vc.labelDefaultColor];

	NSString *msg = [NSString stringWithFormat:@"%@ - %@",p1,p2];
	cell.label.text = msg;
	if (![Utils isEmpty:li.imageURI]) {
		UIImage *img = [DashUtils loadImageResource:li.imageURI userDataDir:self.vc.parentCtrl.dashboard.account.cacheURL];
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

@implementation CustomItemHandler

- (void)textViewDidChange:(UITextView *)textView {
	[UIView setAnimationsEnabled:NO];
	[self.vc.tableView beginUpdates];
	[self.vc.tableView endUpdates];
	[UIView setAnimationsEnabled:YES];
}

- (void)keyboardNotification:(NSNotification*)notification {
	if (self.vc.htmlTextView.isFirstResponder) {
		[self scrollToInsertionPointOf:self.vc.htmlTextView];
	}
}

-(void)textViewDidChangeSelection:(UITextView *)textView {
	[self scrollToInsertionPointOf:textView];
}

// Scroll table view – if necessary – to make the current insertion point
// (caret) of the text field visible.
- (void)scrollToInsertionPointOf:(UITextView *)textView {
	if (textView.isFirstResponder) {
		UITextRange *range = textView.selectedTextRange;
		if (range != nil) {
			// Workaround from https://stackoverflow.com/a/26280994 :
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
						   dispatch_get_main_queue(), ^{
							   UITextPosition *pos = range.end;
							   UITextPosition *start = textView.beginningOfDocument;
							   UITextPosition *end = textView.endOfDocument;
							   if ([textView comparePosition:start toPosition: pos] != NSOrderedDescending
								   && [textView comparePosition:pos toPosition: end] != NSOrderedDescending) {
								   
								   CGRect r1 = [textView caretRectForPosition:range.end];
								   CGRect r2 = [textView convertRect:r1 toView:self.vc.tableView];
								   [self.vc.tableView scrollRectToVisible:r2 animated:NO];
							   }
						   });
		}
	}
}

@end

@implementation EditOptionListResult

@end
