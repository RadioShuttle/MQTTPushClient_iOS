/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCollectionViewController.h"
#import "MessageListTableViewController.h"
#import "DashDetailViewController.h"
#import "Connection.h"
#import "Utils.h"
#import "MqttUtils.h"
#import "DashConsts.h"
#import "NSDictionary+HelSafeAccessors.h"

#import "DashGroupItemViewCell.h"

#import "DashTextItemViewCell.h"

#import "DashTextItem.h"
#import "DashCustomItem.h"
#import "DashSwitchItem.h"
#import "DashSliderItem.h"
#import "DashOptionItem.h"
#import "DashCustomItemViewCell.h"

#import "DashJavaScriptTask.h"

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
	self.preferences = [Dashboard setPreferredViewDashboard:YES forAccount:self.account];
	
	// Uncomment the following line to preserve selection between presentations
	// self.clearsSelectionOnViewWillAppear = NO;
	
	/* calc label height and pass it to layout object. IMPORTANT: specify correct font and size (see storyboard) */
	NSAttributedString* labelString = [[NSAttributedString alloc] initWithString:@"Dummy" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0]}];
	CGRect cellRect = [labelString boundingRectWithSize:CGSizeMake(100.0f, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
	// sets height to DASH_ZOOM_X + cellRect.size.height
	self.dashCollectionFlowLayout.labelHeight = cellRect.size.height;
	self.dashCollectionFlowLayout.zoomLevel = [[self.preferences helNumberForKey:@"zoom_level"] intValue];
	
	/* init Dashboard */
	self.dashboard = [[Dashboard alloc] initWithAccount:self.account];
	self.registeredCustomViewTypes = 0;
	[self registerCustomViewCell];
	
	/* java script task executor */
	self.jsOperationQueue = [[NSOperationQueue alloc] init];
	[self.jsOperationQueue setMaxConcurrentOperationCount:DASH_MAX_CONCURRENT_JS_TASKS];
	self.jsTaskQueue = [NSMutableArray new];
	
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

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
	if (segue.sourceViewController == self.activeDetailView) {
		self.activeDetailView = nil;
		NSLog(@"prepare for unwind.");
	}
}

/* must be called after a new dashboard has been set up */
-(void)registerCustomViewCell {
	DashGroupItem *groupItem;
	DashItem *item;
	
	// TODO: consider limiting no of registrations (e.g. limit to 20)	
	/* find dash object */
	int z = 0;
	for(int i = 0; i < self.dashboard.groups.count; i++) {
		groupItem = self.dashboard.groups[i];
		NSArray<DashItem *> *items = self.dashboard.groupItems[@(groupItem.id_)];
		for(int j = 0; j < items.count; j++) {
			item = items[j];
			if ([item class] == [DashCustomItem class]) {
				((DashCustomItem *) item).cellReuseID = [NSString stringWithFormat:@"%@%d", reuseIDcustomItem, z];
				if (z == self.registeredCustomViewTypes) {
					[self.collectionView registerClass:[DashCustomItemViewCell class] forCellWithReuseIdentifier:((DashCustomItem *) item).cellReuseID];
					self.registeredCustomViewTypes++;
				}
				z++;
			}
		}
	}
}


#pragma mark - Timer
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	/* if timer is active, all observers are still running. this happens if a detail view was shown previously */
	if (!self.timer) {
		[self startTimer];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRequestFinished:) name:@"ServerUpdateNotification" object:self.connection];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onJavaScriptTaskFinished:) name:@"DashJavaScriptTaskNotification" object:nil];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	/* do not remove observer when reason for disappearing is displaying a detail view */
	if (!self.activeDetailView) {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[self stopTimer];
		
		/* save preferneces */
		NSMutableDictionary * prefs = [self.preferences mutableCopy];
		[prefs setObject:[NSNumber numberWithInt:self.dashCollectionFlowLayout.zoomLevel] forKey:@"zoom_level"];
		[Dashboard saveDashboardSettings:self.account settings:prefs];
		
		/* save last received messages */
		[self.dashboard saveMessages];
	}
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
				[self registerCustomViewCell];
				dashboardUpdate = [[resultInfo helNumberForKey:@"dashboard_new"] boolValue];
				msg = [notif.userInfo helStringForKey:@"dashboard_err"];
				if (self.activeDetailView) {
					/* notify detail view about change */
					[self.activeDetailView onDashboardUpdate];
				}
			}
			
			NSArray<DashMessage *> *dashMessages = [notif.userInfo helArrayForKey:@"dashMessages"];
			NSDate *msgsSinceDate = nil;
			int msgsSinceSeqNo = 0;
			if ([dashMessages count] > 0) {
				msgsSinceDate = [notif.userInfo helDateForKey:@"msgs_since_date"];
				msgsSinceSeqNo = [[notif.userInfo helNumberForKey:@"msgs_since_seqno"] intValue];
				[self.dashboard addNewMessages:dashMessages];
			}
			
			NSDictionary<NSString *, NSArray<DashMessage *> *> *historicalData = [notif.userInfo helDictForKey:@"historicalData"];
			if (historicalData.count > 0) {
				[self.dashboard addHistoricalData:historicalData];
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
	
	/* cancel long running java script tasks */
	[self checkJSTasks];
	
	/* javascript tasks grouped per dash object, since there can be multiple message objects matching a dash's subscription.for these objects the js execution order is important */
	NSMutableDictionary<NSNumber *, NSMutableArray<NSInvocationOperation *> *> *dependenciesDict = [NSMutableDictionary new];
	
	
	for(int i = 0; i < [dashMessages count]; i++) {
		[self onNewMessage:dashMessages[i] indexPathDict:indexPathDict dependencies:dependenciesDict];
	}
	
	/* add new tasks to queue */
	enumerator = [dependenciesDict objectEnumerator];
	NSMutableArray<NSInvocationOperation *> *taskArray;
	while ((taskArray = [enumerator nextObject])) {
		for(int i = 0; i < taskArray.count; i++) {
			[self.jsTaskQueue addObject:taskArray[i]];
		}
	}
	
	if (notify && indexPathDict.count > 0) {
		NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray new];
		NSEnumerator *enumerator = [indexPathDict objectEnumerator];
		NSIndexPath *value;
		
		while ((value = [enumerator nextObject])) {
			[indexPaths addObject:value];
		}
		[self.collectionView reloadItemsAtIndexPaths:indexPaths];
		if (self.activeDetailView) {
			if ([indexPathDict objectForKey:[NSNumber numberWithUnsignedLong:self.activeDetailView.dashItem.id_]]) {
				[self.activeDetailView onNewMessage];
			}
		}
	}
}

-(void)onNewMessage:(DashMessage *)msg indexPathDict:(NSMutableDictionary<NSNumber *, NSIndexPath *> *)indexPathDict dependencies:(NSMutableDictionary<NSNumber *, NSMutableArray<NSInvocationOperation *> *> *) dependenciesDict{
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
						if ([item class] == [DashCustomItem class]) {
							((DashCustomItem *) item).message = msg;
						}
						item.content = [[NSString alloc]initWithData:msg.content encoding:NSUTF8StringEncoding];
						if (indexPathDict) {
							NSIndexPath *loc = [NSIndexPath indexPathForRow:j inSection:i];
							[indexPathDict setObject:loc forKey:[NSNumber numberWithUnsignedLong:item.id_]];
						}
					} else {
						/* trigger java script execution */
						DashJavaScriptTask *jsTask = [[DashJavaScriptTask alloc]initWithItem:item message:msg version:self.dashboard.localVersion account:self.dashboard.account];
						
						NSInvocationOperation *op = [[NSInvocationOperation alloc]initWithTarget:jsTask selector:@selector(execute) object:nil];
						
						NSMutableArray<NSInvocationOperation *> * q = dependenciesDict[@(item.id_)];
						if (!q) {
							q = [NSMutableArray new];
							dependenciesDict[@(item.id_)] = q;
						}
						
						if (q.count > 0) {
							[op addDependency:q.lastObject];
						}
						
						[q addObject:op];
						[self.jsOperationQueue addOperation:op];
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

- (void)onJavaScriptTaskFinished:(NSNotification *)notif {
	uint64_t version = [[notif.userInfo helNumberForKey:@"version"] unsignedLongLongValue];
	
	/* still correct dashboard ? then deliver result */
	if (version > 0 && version == self.dashboard.localVersion) {
		uint32_t oid = [[notif.userInfo helNumberForKey:@"id"] unsignedIntValue];
		
		NSMutableArray * indexPaths = [NSMutableArray new];
		if ([self.dashboard getItemForID:oid indexPathArr:indexPaths]) {
			/* notify dash object about update */
			[self.collectionView reloadItemsAtIndexPaths:indexPaths];
			//TODO: update detail view dialog
		}
	}
}

/* cancel java script tasks, which are in queue for long time*/
-(void)checkJSTasks {
	
	NSMutableIndexSet *discardedItems = [NSMutableIndexSet indexSet];
	NSInvocationOperation *operation;
	DashJavaScriptTask *task;
	NSTimeInterval timeInterval;
	NSDate *now = [NSDate new];
	
	for(int i = 0; i < self.jsTaskQueue.count; i++) {
		operation = self.jsTaskQueue[i];
		if (operation.isFinished || operation.isCancelled) {
			[discardedItems addIndex:i];
		} else {
			task = operation.invocation.target;
			timeInterval = [now timeIntervalSinceDate:task.timestamp];
			if (timeInterval > DASH_MAX_JS_TASKS_QUEUE_TIME) {
				[operation cancel];
				[discardedItems addIndex:i];
			}
		}
	}
	[self.jsTaskQueue removeObjectsAtIndexes:discardedItems];
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
	if (!self.timer) {
		[self.connection getDashboardForAccount:self.dashboard];
		self.timer = [NSTimer scheduledTimerWithTimeInterval:DASH_TIMER_INTERVAL_SEC repeats:YES block:^(NSTimer * _Nonnull timer) {
			// NSLog(@"xxxx no of acitve connection %d", [self.connection activeDashboardRequests]);
			if ([self.connection activeDashboardRequests] == 0) {
				[self.connection getDashboardForAccount:self.dashboard];
			}
		}];
	}
	
}

-(void) stopTimer {
	if (self.timer) {
		[self.timer invalidate];
		self.timer = nil;
	}
}

#pragma mark - Navigation

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
	
	DashItem *group = [self.dashboard.groups objectAtIndex:[indexPath section]];
	NSNumber *key = [NSNumber numberWithUnsignedInt:group.id_];
	DashItem *item = [(NSArray *) [self.dashboard.groupItems objectForKey:key] objectAtIndex:[indexPath row]];
	
	CGRect sourceRect = [collectionView layoutAttributesForItemAtIndexPath:indexPath].frame;
	
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Dashboard" bundle:nil];
	DashDetailViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"DashDetailViewController"];
	vc.dashItem = (DashItem *) item;
	vc.dashboard = self.dashboard;
	self.activeDetailView = vc;
	
	vc.modalPresentationStyle = UIModalPresentationPopover;
	
	
	vc.popoverPresentationController.sourceView = collectionView;
	vc.popoverPresentationController.sourceRect = sourceRect;
	
	[self presentViewController:vc animated:YES completion:nil];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	DashCollectionViewCell *cell;
	
	DashItem *group = [self.dashboard.groups objectAtIndex:[indexPath section]];
	NSNumber *key = [NSNumber numberWithUnsignedInt:group.id_];
	DashItem *item = [(NSArray *) [self.dashboard.groupItems objectForKey:key] objectAtIndex:[indexPath row]];
	
	if ([DashCustomItem class] == [item class]) {
		if (((DashCustomItem *) item).cellReuseID) {
			cell = [collectionView dequeueReusableCellWithReuseIdentifier:((DashCustomItem *) item).cellReuseID forIndexPath:indexPath];
		} else {
			cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDcustomItem forIndexPath:indexPath];
		}
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
	
	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	DashGroupItemViewCell *v = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseIGroupItem forIndexPath:indexPath];
	DashItem *group = [self.dashboard.groups objectAtIndex:[indexPath section]];
	
	// layout info needed in layout pass (only for header)
	[v onBind:group layoutInfo:((DashCollectionFlowLayout *) self.collectionViewLayout).layoutInfo];
	return v;
}

-(void)dealloc {
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
