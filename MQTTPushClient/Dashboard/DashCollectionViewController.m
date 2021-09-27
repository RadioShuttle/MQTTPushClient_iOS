/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCollectionViewController.h"
#import "MessageListTableViewController.h"
#import "Connection.h"
#import "Utils.h"
#import "MqttUtils.h"
#import "DashConsts.h"
#import "NSDictionary+HelSafeAccessors.h"

#import "DashGroupItemView.h"
#import "DashTextItemView.h"
#import "DashSwitchItemView.h"
#import "DashSliderItemView.h"
#import "DashOptionItemView.h"

#import "DashTextItemViewCell.h"
#import "DashCustomItemViewCell.h"
#import "DashCollectionViewCell.h"
#import "DashSwitchItemViewCell.h"
#import "DashSliderItemViewCell.h"
#import "DashOptionItemViewCell.h"

#import "DashTextItem.h"
#import "DashCustomItem.h"
#import "DashSwitchItem.h"
#import "DashSliderItem.h"
#import "DashOptionItem.h"

@interface DashCollectionViewController ()
@property NSDate *statusBarUpdateTime;
@end

@implementation DashCollectionViewController

static NSString * const reuseIDtextItem = @"textItemCell";
static NSString * const reuseIDcustomItem = @"customItemCell";
static NSString * const reuseIDswitchItem = @"switchItemCell";
static NSString * const reuseIDsliderItem = @"sliderItemCell";
static NSString * const reuseIDoptionItem = @"optionItemCell";
static NSString * const reuseIGroupItem = @"groupItemCell";


- (void)viewDidLoad {
    [super viewDidLoad];
	[Dashboard setPreferredViewDashboard:YES forAccount:self.account];
	
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
	/* calc label height and pass it to layout object. IMPORTANT: specify correct font and size (see storyboard) */
	NSAttributedString* labelString = [[NSAttributedString alloc] initWithString:@"Dummy" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0]}];
	CGRect cellRect = [labelString boundingRectWithSize:CGSizeMake(100.0f, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
	// sets height to DASH_ZOOM_X + cellRect.size.height
	self.dashCollectionFlowLayout.labelHeight = cellRect.size.height;
	
	/* init Dashboard */
	self.dashboard = [[Dashboard alloc] initWithAccount:self.account];
	
	/* deliver local stored messages*/
	[self deliverMessages:[[NSDate alloc]initWithTimeIntervalSince1970:0] seqNo:0 notify:NO];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSString *identifier = segue.identifier;
	if ([identifier isEqualToString:@"IDShowMessageList"]) {
		MessageListTableViewController *vc = segue.destinationViewController;
		vc.account = self.dashboard.account;
	}
}

#pragma mark - Timer
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRequestFinished:) name:@"ServerUpdateNotification" object:self.connection];
	
	[self startTimer];
}

- (void)viewWillDisappear:(BOOL)a {
	[super viewWillDisappear:a];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self stopTimer];
	[self.dashboard saveMessages];
}

- (void)onRequestFinished:(NSNotification *)notif {
	if (self.account.error) {
		[self showErrorMessage:self.account.error.localizedDescription];
	} else {
		BOOL dashboardUpdate = NO;
		NSString *msg;
		NSString *response = [notif.userInfo helStringForKey:@"response"];
		if ([response isEqualToString:@"getDashboardRequest"]) {
			uint64_t serverVersion = [[notif.userInfo helNumberForKey:@"serverVersion"] unsignedLongLongValue];
			if (serverVersion > 0) {
				/* received a new dashboard */
				NSString *dashboardJS = [notif.userInfo helStringForKey:@"dashboardJS"];
				// NSLog(@"Dashboard: %@", dashboardJS);
				
				NSDictionary * resultInfo = [self.dashboard setDashboard:dashboardJS version:serverVersion];
				dashboardUpdate = [[resultInfo helNumberForKey:@"dashboard_new"] boolValue];
				msg = [notif.userInfo helStringForKey:@"dashboard_err"];
			}
			
			NSArray<DashMessage *> *dashMessages = [notif.userInfo helArrayForKey:@"dashMessages"];
			NSDate *msgsSinceDate = nil;
			int msgsSinceSeqNo = 0;
			if ([dashMessages count] > 0) {
				msgsSinceDate = [notif.userInfo helDateForKey:@"msgs_since_date"];
				msgsSinceSeqNo = [[notif.userInfo helNumberForKey:@"msgs_since_seqno"] intValue];
				[self.dashboard addNewMessages:dashMessages];
			}
			
			if (dashboardUpdate) {
				/* dashboard update? deliver all messages (cached and new messages) */
				[self deliverMessages:[NSDate dateWithTimeIntervalSince1970:0L] seqNo:0 notify:NO];
				[self.collectionView reloadData];
			} else if ([dashMessages count] > 0) {
				/* deliver new messages */
				[self deliverMessages:msgsSinceDate seqNo:msgsSinceSeqNo notify:YES];
			}

		}
		/* show error/info message or reset status bar*/
		[self showErrorMessage:msg];
	}
}

-(void)deliverMessages:(NSDate *)since seqNo:(int) seqNo notify:(BOOL)notify {
	NSEnumerator *enumerator = [self.dashboard.lastReceivedMsgs objectEnumerator];
	DashMessage *msg;
	
	NSMutableArray<DashMessage *> *filteredDashMessages = [NSMutableArray new];
	while ((msg = [enumerator nextObject])) {
		NSComparisonResult res = [since compare:msg.timestamp];
		/* filter already delivered messages */
		if (res == NSOrderedAscending || (res == NSOrderedSame && seqNo < msg.messageID)) {
			[filteredDashMessages addObject:msg];
		}
	}
	/* messages must be sorted ascending before being processed */
	NSComparisonResult (^sortFunc)(DashMessage *, DashMessage *) = ^(DashMessage *obj1, DashMessage *obj2) {
		NSComparisonResult r = [obj1.timestamp compare:obj2.timestamp];
		if (r == NSOrderedSame) {
			if (obj1.messageID < obj2.messageID) {
				r = NSOrderedAscending;
			} else if (obj1.messageID > obj2.messageID) {
				r = NSOrderedDescending;
			}
		}
		return r;
	};
	NSArray<DashMessage *> *dashMessages = [filteredDashMessages sortedArrayUsingComparator: sortFunc];
	/* will contain items to update */
	NSMutableDictionary<NSNumber *, NSIndexPath *> *indexPathDict;
	if (notify) {
		indexPathDict = [NSMutableDictionary new];
	}
	
	for(int i = 0; i < [dashMessages count]; i++) {
		[self onNewMessage:dashMessages[i] indexPathDict:indexPathDict];
	}
	
	if (notify && indexPathDict.count > 0) {
		NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray new];
		NSEnumerator *enumerator = [indexPathDict objectEnumerator];
		NSIndexPath *value;
		
		while ((value = [enumerator nextObject])) {
			[indexPaths addObject:value];
		}
		[self.collectionView reloadItemsAtIndexPaths:indexPaths];		
	}
}

-(void)onNewMessage:(DashMessage *)msg indexPathDict:(NSMutableDictionary<NSNumber *, NSIndexPath *> *)indexPathDict {
	DashGroupItem *groupItem;
	BOOL matches = NO;
	for(int i = 0; i < self.dashboard.groups.count; i++) {
		groupItem = self.dashboard.groups[i];
		NSArray<DashItem *> *items = self.dashboard.groupItems[[NSNumber numberWithUnsignedLong:groupItem.id_]];
		DashItem *item;
		for(int j = 0; j < items.count; j++) {
			item = items[j];
			@try {
				if (![Utils isEmpty:item.topic_s] && [MqttUtils topicIsMatched:item.topic_s topic:msg.topic] ) {
					matches = YES;
					if ([Utils isEmpty:item.script_f]) {
						//TODO: set content
						item.content = [[NSString alloc]initWithData:msg.content encoding:NSUTF8StringEncoding];
						if (indexPathDict) {
							NSIndexPath *loc = [NSIndexPath indexPathForRow:j inSection:i];
							[indexPathDict setObject:loc forKey:[NSNumber numberWithUnsignedLong:item.id_]];
						}
					} else {
						//TODO: trigger javascript here. remove lines
						item.content = [[NSString alloc]initWithData:msg.content encoding:NSUTF8StringEncoding];
						if (indexPathDict) {
							NSIndexPath *loc = [NSIndexPath indexPathForRow:j inSection:i];
							[indexPathDict setObject:loc forKey:[NSNumber numberWithUnsignedLong:item.id_]];
						}
						//TODO: end remove lines
					}
				}
			} @catch(NSException *exception) {
				NSLog(@"Error: %@", exception.reason); //topic validation error (should never occur since the stored topics are validated)
			}
		}
	}
	if (!matches && ![Utils isEmpty:msg.topic]) {
		/* no matches found, which can happen it the dasboard has been updated */
		[self.dashboard.lastReceivedMsgs removeObjectForKey:msg.topic];
	}
}

- (void)showErrorMessage:(NSString *)msg {
	if ([Utils isEmpty:msg]) {
		BOOL clear = YES;
		/* make sure an error message is displayed at least for 5 sec */
		if (![Utils isEmpty:self.statusBarLabel.text]) {
			if (self.statusBarUpdateTime) {
				NSTimeInterval ti = -[self.statusBarUpdateTime timeIntervalSinceNow];
				if (ti < DASH_TIMER_INTERVAL_SEC) {
					clear = NO;
				}
			}
		}
		if (clear) {
			self.statusBarLabel.text = @"";
			self.statusBarUpdateTime = nil;
		}
	} else {
		self.statusBarLabel.text = msg;
		self.statusBarUpdateTime = [[NSDate alloc] init];
	}
}
-(void) startTimer {
	if (!self.connection) {
		self.connection = [[Connection alloc] init];
	}
	self.timer = [NSTimer scheduledTimerWithTimeInterval:DASH_TIMER_INTERVAL_SEC repeats:YES block:^(NSTimer * _Nonnull timer) {
		// NSLog(@"xxxx no of acitve connection %d", [self.connection activeDashboardRequests]);
		if ([self.connection activeDashboardRequests] == 0) {
			[self.connection getDashboardForAccount:self.dashboard];
		}
	}];
}

-(void) stopTimer {
	if (self.timer) {
		[self.timer invalidate];
		self.timer = nil;
	}
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)actionZoom:(id)sender {
	[self.dashCollectionFlowLayout zoom];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return self.dashboard.groups.count;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	int n = 0;
	if (section < self.dashboard.groups.count) {
		DashGroupItem *group = self.dashboard.groups[section];
		n = (int) [[self.dashboard.groupItems objectForKey:[NSNumber numberWithUnsignedInt:group.id_]] count];
	}
    return n;
}

#pragma mark <UICollectionViewDelegate>

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
	// item click
	NSLog(@"item selected");
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	DashCollectionViewCell *cell;
	
	DashItem *group = [self.dashboard.groups objectAtIndex:[indexPath section]];
	NSNumber *key = [NSNumber numberWithUnsignedInt:group.id_];
	DashItem *item = [(NSArray *) [self.dashboard.groupItems objectForKey:key] objectAtIndex:[indexPath row]];
	
	if ([DashCustomItem class] == [item class]) {
		cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDcustomItem forIndexPath:indexPath];
	} else if ([DashTextItem class] == [item class]) {
		cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDtextItem forIndexPath:indexPath];			
	} else if ([DashSwitchItem class] == [item class]) {
		cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDswitchItem forIndexPath:indexPath];
	} else if ([DashSliderItem class] == [item class]) {
		cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDsliderItem forIndexPath:indexPath];
	} else if ([DashOptionItem class] == [item class]) {
		cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDoptionItem forIndexPath:indexPath];
	}
	
	cell.dashItem = item;
	[cell onBind:item context:self.dashboard];
	
	/*
	 * TODO: prototpy code below can be removed when all onBind() functions of reusable views have been implemented
	 */
	

	int64_t bg = item.background;
	if (bg >= DASH_COLOR_OS_DEFAULT) {
		bg = DASH_DEFAULT_CELL_COLOR; // TODO: dark mode
	}
	

	
	UIColor *textColor;
	if (item.textcolor >= DASH_COLOR_OS_DEFAULT) {
		textColor = [UILabel new].textColor;
	} else {
		textColor = UIColorFromRGB(item.textcolor);
	}	
	
	if ([DashCustomItem class] == [item class]) {
		/* Custom Item (Web) */
		DashCustomItem *customItem = (DashCustomItem *) item;
		DashCustomItemViewCell *cv = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDcustomItem forIndexPath:indexPath];
		cell = cv;
		
		Boolean load = NO;
		if (!cv.dashItem) { // the cell is new
			/* add log and error message handler */
			[cv.webviewContainer.webView.configuration.userContentController addScriptMessageHandler:cv name:@"error"];
			[cv.webviewContainer.webView.configuration.userContentController addScriptMessageHandler:cv name:@"log"];
			load = YES;
			cv.webviewContainer.userInteractionEnabled = NO;
			NSLog(@"Custom Item View (including webview): created");
		} else if (cv.dashItem == customItem) { // cell view has not been reused for a diffrent custom item
			NSLog(@"Custom Item View (including webview): update data");
			//update data
			
		} else { // cell has been reused
			NSLog(@"Custom Item View (including webview): recycled");
			[cv.webviewContainer.webView.configuration.userContentController removeAllUserScripts];
			load = YES;
		}
		cv.dashItem = customItem;
		if (load) {
			[cv.webviewContainer showProgressBar];
			/* background color */
			cv.webviewContainer.webView.opaque = NO;
			[cv.webviewContainer.webView setBackgroundColor:UIColorFromRGB(bg)];
			[cv.webviewContainer.webView.scrollView setBackgroundColor:UIColorFromRGB(bg)];
			
			/* add error function */
			WKUserScript *errHandlerSkript = [[WKUserScript alloc] initWithSource:[[NSString alloc] initWithData:[[NSDataAsset alloc] initWithName:@"error_handler"].data encoding:NSUTF8StringEncoding] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
			[cv.webviewContainer.webView.configuration.userContentController addUserScript:errHandlerSkript];
			
			/* add log function */
			WKUserScript *logSkript = [[WKUserScript alloc] initWithSource:@"function log(t) {window.webkit.messageHandlers.log.postMessage(t);}" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
			[cv.webviewContainer.webView.configuration.userContentController addUserScript:logSkript];
			
			/* call Dash-javascript init function: */
			WKUserScript *initSkript = [[WKUserScript alloc] initWithSource:@"onMqttInit(); log('Clock app initialized!');" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
			[cv.webviewContainer.webView.configuration.userContentController addUserScript:initSkript];
			
			[cv.webviewContainer.webView loadHTMLString:customItem.html baseURL:[NSURL URLWithString:@"pushapp://pushclient/"]];
		}
		
		/* when passing messages to custom view use: [webView evaluateJavaScript:@"onMqttMessage(...); " completionHandler:^(NSString *result, NSError *error) {}] */
		/* When using [webView evaluateJavaScript ...] the document must have been fully loaded! This can be checked with via WKNavigationDelegate.didFinishNavigation callback */
		cv.webviewContainer.webView.navigationDelegate = cv.webviewContainer;
		
		
		[cv.customItemLabel setText:customItem.label];
		
	} else if ([DashSwitchItem class] == [item class]) {
		/* Switch */
		DashSwitchItem *switchItem = (DashSwitchItem *) item;
		DashSwitchItemViewCell *sw = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDswitchItem forIndexPath:indexPath];
		DashSwitchItemView *view = ((DashSwitchItemView *) sw.itemContainer);
		view.button.userInteractionEnabled = NO;
		sw.dashItem = switchItem;
		//NSLog(@"switch is on state: %d", [switchItem isOnState]);
		int64_t buttonTintColor;
		NSString *buttonTitle;
		NSString *imageURI;
		if ([switchItem isOnState]) {
			buttonTitle = switchItem.val;
			buttonTintColor = switchItem.color;
			imageURI = switchItem.uri;
		} else {
			buttonTitle = switchItem.valOff;
			buttonTintColor = switchItem.colorOff;
			imageURI = switchItem.uriOff;
		}
		if (buttonTintColor >= DASH_COLOR_CLEAR) {
			[view.button setTintColor:nil];
		} else if (buttonTintColor >= DASH_COLOR_OS_DEFAULT) {
			UIColor *textColor = [UILabel new].textColor;
			[view.button setTintColor:textColor];
		} else {
			[view.button setTintColor:UIColorFromRGB(buttonTintColor)];
		}
		UIImage *image;
		if (imageURI.length > 0) {
			//TODO: handle user images and errors
			NSURL *u = [NSURL URLWithString:imageURI];
			NSString *internalResourceName = [u lastPathComponent]; //TODO: assuming internal image here
			image = [UIImage imageNamed:internalResourceName];
		}
		if (image) {
			view.button.imageView.contentMode = UIViewContentModeScaleAspectFit;
			view.button.imageEdgeInsets = UIEdgeInsetsMake(16,16,16,16);
			view.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
			[view.button setImage:image forState:UIControlStateNormal];
			view.button.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
			
			[view.button setTitle:nil forState:UIControlStateNormal];
		} else {
			[view.button setImage:nil forState:UIControlStateNormal];
			[view.button setTitle:buttonTitle forState:UIControlStateNormal];
		}
		
		[sw.itemLabel setText:item.label];
		[sw.itemContainer setBackgroundColor:UIColorFromRGB(bg)];
		cell = sw;
	} else if ([DashSliderItem class] == [item class]) {
		/* Slider Item */
		DashSliderItem *sliderItem = (DashSliderItem *) item;
		DashSliderItemViewCell *sv = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDsliderItem forIndexPath:indexPath];
		sv.dashItem = sliderItem;
		
		DashSliderItemView *view = (DashSliderItemView *) sv.itemContainer ;
		UIColor *progressTintColor = nil;
		
		double progress = [DashSliderItem calcProgressInPercent:[sliderItem.content doubleValue] min:sliderItem.range_min max:sliderItem.range_max];
		
		NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
		[formatter setMaximumFractionDigits:sliderItem.decimal];
		[formatter setRoundingMode: NSNumberFormatterRoundHalfUp];
		
		NSString * val = [formatter stringFromNumber:[NSNumber numberWithFloat:progress]];
		if (sliderItem.percent) {
			val = [NSString stringWithFormat:@"%@%%", val];
		}
		[view.valueLabel setText:val];
		[view.progressView setProgress:progress / 100.0f];
		if (sliderItem.progresscolor < DASH_COLOR_OS_DEFAULT) {
			progressTintColor = UIColorFromRGB(sliderItem.progresscolor);
		}
		[view.progressView setProgressTintColor:progressTintColor];
		
		[sv.itemLabel setText:item.label];
		[sv.itemContainer setBackgroundColor:UIColorFromRGB(bg)];
		cell = sv;
	} else if ([DashOptionItem class] == [item class]) {
		DashOptionItem *optionItem = (DashOptionItem *) item;
		DashOptionItemViewCell *ov = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDoptionItem forIndexPath:indexPath];
		ov.dashItem = optionItem;
		
		NSString *txt = optionItem.content;
		DashOptionListItem *e;
		for(int i = 0; i < optionItem.optionList.count; i++) {
			e = [optionItem.optionList objectAtIndex:i];
			if ([e.value isEqualToString:txt]) {
				if ([Utils isEmpty:e.displayValue]) {
					txt = e.value;
				} else {
					txt = e.displayValue;
				}
				break;
			}
		}
		DashOptionItemView *view = (DashOptionItemView *) ov.itemContainer;
		[view.valueLabel setText:txt];
		
		[ov.itemLabel setText:item.label];
		[ov.itemContainer setBackgroundColor:UIColorFromRGB(bg)];
		cell = ov;
	}
	
	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	DashGroupItemView *v = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"groupItemCell" forIndexPath:indexPath];
	DashItem *group = [self.dashboard.groups objectAtIndex:[indexPath section]];
	
	int64_t bg = group.background;
	if (bg >= DASH_COLOR_OS_DEFAULT) {
		bg = DASH_DEFAULT_CELL_COLOR; // TODO: dark mode
	}
	
	UIColor *textColor;
	if (group.textcolor >= DASH_COLOR_OS_DEFAULT) {
		textColor = [UILabel new].textColor;
	} else {
		textColor = UIColorFromRGB(group.textcolor);
	}
	
	[v.groupViewContainer setBackgroundColor:UIColorFromRGB(bg)];
	[v.groupViewLabel setTextColor:textColor];
	[v.groupViewLabel setText:group.label];
	
	// layout info needed in layout pass (only for header)
	v.layoutInfo = ((DashCollectionFlowLayout *) self.collectionViewLayout).layoutInfo;
	
	return v;
}

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
