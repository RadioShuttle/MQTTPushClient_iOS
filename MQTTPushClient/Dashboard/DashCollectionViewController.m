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
#import "DashGroupItemViewCell.h"
#import "DashTextItemViewCell.h"
#import "DashTextItem.h"
#import "DashCustomItem.h"
#import "DashSwitchItem.h"
#import "DashSliderItem.h"
#import "DashOptionItem.h"
#import "DashCustomItemViewCell.h"
#import "DashEditItemViewController.h"
#import "DashManageImagesController.h"
#import "DashUtils.h"

#import "DashJavaScriptTask.h"

@interface DashCollectionViewController ()
@property NSDate *statusBarUpdateTime;
@property NSArray<UIBarButtonItem *> *buttonItemsHeaderNonEditMode;
@property NSArray<UIBarButtonItem *> *buttonItemsHeaderEditMode;
@property NSArray<UIBarButtonItem *> *buttonItemsFooterEditMode;
@property NSArray<UIBarButtonItem *> *buttonItemsFooterNonEditMode;
@property Mode argEditMode;
@property DashItem *argEditItem;

@property UIActivityIndicatorView *progressBar;

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
	
	// Uncomment the following line to preserve selection between presentations
	// self.clearsSelectionOnViewWillAppear = NO;
	
	self.preferences = [Dashboard loadDashboardSettings:self.account];
	
	/* calc label height and pass it to layout object. IMPORTANT: specify correct font and size (see storyboard) */
	NSAttributedString* labelString = [[NSAttributedString alloc] initWithString:@"Dummy" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0]}];
	CGRect cellRect = [labelString boundingRectWithSize:CGSizeMake(100.0f, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
	
	// sets height to DASH_ZOOM_X + cellRect.size.height
	self.dashCollectionFlowLayout.labelHeight = cellRect.size.height;
	self.dashCollectionFlowLayout.zoomLevel = [[self.preferences helNumberForKey:@"zoom_level"] intValue];
	
	/* init Dashboard */
	self.dashboard = [[Dashboard alloc] initWithAccount:self.account];
	[self.collectionView registerClass:[DashCustomItemViewCell class] forCellWithReuseIdentifier:reuseIDcustomItem];
	self.selectedItems = [NSMutableArray new];
	
	/* java script task executor */
	self.jsOperationQueue = [[NSOperationQueue alloc] init];
	[self.jsOperationQueue setMaxConcurrentOperationCount:DASH_MAX_CONCURRENT_JS_TASKS];
	self.jsTaskQueue = [NSMutableArray new];
	self.publishReqIDCounter = 0;
	
	self.saveRequestCnt = 0;
	
	/* deliver local stored messages*/
	[self deliverMessages:[[NSDate alloc]initWithTimeIntervalSince1970:0] seqNo:0 notify:NO];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSString *identifier = segue.identifier;
	if ([identifier isEqualToString:@"IDShowMessageList"]) {
		MessageListTableViewController *vc = segue.destinationViewController;
		vc.account = self.dashboard.account;
	} else if ([segue.destinationViewController isKindOfClass:[DashEditItemViewController class]]) {
		DashEditItemViewController *vc = segue.destinationViewController;
		vc.mode = self.argEditMode;
		vc.item = self.argEditItem;
		vc.parentCtrl = self;
	}
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
	if (segue.sourceViewController == self.activeDetailView) {
		self.activeDetailView = nil;
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
	/* disable sleep mode while dashboard is being displayed */
	[UIApplication sharedApplication].idleTimerDisabled = YES;
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
		[prefs setObject:[NSNumber numberWithBool:YES] forKey:@"showDashboard"];
		[Dashboard saveDashboardSettings:self.account settings:prefs];
		
		/* save last received messages */
		[self.dashboard saveMessages];
	}
	
	[UIApplication sharedApplication].idleTimerDisabled = NO;
}

-(BOOL)checkIfUpdateRequired {
	BOOL updateRequired = self.dashboard.protocolVersion != -1 && self.dashboard.protocolVersion > DASHBOARD_PROTOCOL_VERSION;
	if (updateRequired) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Update required" message:@"This dashboard was created with a newer version. To modify the dashboard, update this app." preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {;
		}]];
		// [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
		[self presentViewController:alert animated:YES completion:nil];
	}
	
	return updateRequired;
}

- (void)onRequestFinished:(NSNotification *)notif {
	/* publish request */
	uint32_t publishRequestID = [[notif.userInfo helNumberForKey:@"publish_request"] unsignedIntValue];
	if (publishRequestID > 0) {
		uint64_t version = [[notif.userInfo helNumberForKey:@"version"] unsignedLongLongValue];
		if (version > 0 && version == self.dashboard.localVersion) {
			uint32_t item_id = [[notif.userInfo helNumberForKey:@"id"] unsignedIntValue];
			NSMutableArray *indexPath = [NSMutableArray new];
			DashItem *item = [self.dashboard getItemForID:item_id indexPathArr:indexPath];
			if (item) {
				BOOL publishError = NO;
				/* update item error info */
				if (self.account.error) {
					item.error2 = self.account.error.localizedDescription;
					publishError = YES;
				} else {
					item.error2 = nil;
				}
				/*
				 * Notify view which started the publish request, so progress bar can
				 * be hidden (in detail view). Also custom item views must be informed when a
				 * request has been finished, because this info is required in its java
				 * script environment (a new publish command can only be executed in java
				 * script, when the previous one has finished. This is to avoid spaming by
				 * scripts).
				 */
				if (self.activeDetailView) {
					/* vsisible view */
					[self.activeDetailView onPublishRequestFinished:publishRequestID];
				}
				if ([item isKindOfClass:[DashCustomItem class]]) {
					/* special handling for publish requests executed from custom items instances in cell views */
					DashCustomItemView *customItemView = [self.dashboard.cachedCustomViews objectForKey:@(item_id)];
					[customItemView onPublishRequestFinished:publishRequestID];
				}

				/* deliver the message sent (to subscribers). do not wait for next poll request */
				if (!publishError) {
					[self checkJSTasks];
					NSMutableDictionary<NSNumber *, NSMutableArray<NSInvocationOperation *> *> *dependenciesDict = [NSMutableDictionary new];
					NSMutableDictionary<NSNumber *, NSIndexPath *> *indexPathDict = [NSMutableDictionary new];
					DashMessage *msg = [notif.userInfo objectForKey:@"message"];
					if (msg) {
						[self onNewMessage:msg indexPathDict:indexPathDict dependencies:dependenciesDict];
						NSMutableArray<NSInvocationOperation *> *taskArray;
						for (NSNumber *key in dependenciesDict) {
							taskArray = [dependenciesDict objectForKey:key];
							for(int i = 0; i < taskArray.count; i++) {
								[self.jsTaskQueue addObject:taskArray[i]];
							}
						}
						if (indexPathDict.count > 0) {
							NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray new];
							NSIndexPath *value;
							for (NSNumber *key in indexPathDict) {
								value = [indexPathDict objectForKey:key];
								[indexPaths addObject:value];
							}
							[UIView setAnimationsEnabled:NO];
							[self.collectionView reloadItemsAtIndexPaths:indexPaths];
							[UIView setAnimationsEnabled:YES];
							if (self.activeDetailView) {
								if ([indexPathDict objectForKey:[NSNumber numberWithUnsignedLong:self.activeDetailView.dashItem.id_]]) {
									[self.activeDetailView onNewMessage];
								}
							}
						}
					}
				}
			}
		}
		return;
	}
	
	/* if save/delete request, hide progress bar */
	NSNumber *n = [notif.userInfo objectForKey:@"save_request"];
	if (n && [n intValue] == 0) { // is this a delete request?
		[self hideProgressBar];
	}

	if (self.account.error) {
		[self showErrorMessage:self.account.error.localizedDescription];
	} else {
		BOOL dashboardUpdate = NO;
		NSString *msg;
		NSString *response = [notif.userInfo helStringForKey:@"response"];

		/* dashboardrequest */
		if ([response isEqualToString:@"getDashboardRequest"]) {
			uint64_t serverVersion = [[notif.userInfo helNumberForKey:@"serverVersion"] unsignedLongLongValue];
			if (serverVersion > 0) {
				/* received a new dashboard */
				NSString *dashboardJS = [notif.userInfo helStringForKey:@"dashboardJS"];
				// NSLog(@"Dashboard: %@", dashboardJS);
				// msg = [notif.userInfo helStringForKey:@"dashboard_err"];
				BOOL externalUpdate = self.dashboard.localVersion != 0;
				if (externalUpdate) {
					msg = @"Dashboard has been updated.";
				}
				
				NSArray<NSNumber *> *selectedIDs = (self.editMode ? [self.dashboard objectIDsForIndexPaths:self.selectedItems] : nil);
				NSDictionary * resultInfo = [self.dashboard setDashboard:dashboardJS version:serverVersion];
				/* the position of selected items might have changed: */
				if (self.editMode && selectedIDs.count > 0) {
					[self setSelectionForObjects:selectedIDs];
				}
				dashboardUpdate = [[resultInfo helNumberForKey:@"dashboard_new"] boolValue];
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

			/* if resources have been updated, */
			BOOL resourceImageUpdates = [[notif.userInfo helNumberForKey:@"resource_img_update"] boolValue];
			BOOL resourceHtmlUpdates = [[notif.userInfo helNumberForKey:@"resource_html_update"] boolValue];

			if (dashboardUpdate) {
				/* dashboard update? deliver all messages (cached and new messages) */
				[self deliverMessages:[NSDate dateWithTimeIntervalSince1970:0L] seqNo:0 notify:NO];
				[self.collectionView reloadData];
			} else if (resourceHtmlUpdates || resourceImageUpdates) {
				/* received missing resources requires to update UI (including reloading html in custom views) */
				[self onReloadMenuItemClicked];
			} else if ([dashMessages count] > 0) {
				/* deliver new messages */
				[self deliverMessages:msgsSinceDate seqNo:msgsSinceSeqNo notify:YES];
			}
		} else {
			/* save request (delete) */
			NSNumber *n = [notif.userInfo objectForKey:@"save_request"];
			if (n && [n intValue] == 0) { // is this a delete request?
				BOOL invalidVersion = [notif.userInfo helNumberForKey:@"invalidVersion"];
				if (invalidVersion) {
					/* rare case: dashboard was updated on diffrent mobile device and has not been updated yet.
					 (This will be done with the next polling request "getMessages".) */
					msg = @"Deletion failed (version error).";
				} else {
					uint64_t newVersion = [[notif.userInfo helNumberForKey:@"serverVersion"] unsignedLongLongValue];
					NSString *newDashboard = [notif.userInfo helStringForKey:@"dashboardJS"];
					if (newVersion > 0 && newDashboard) {
						[self onDashboardSaved:newDashboard version:newVersion];
					}
				}
			}
		}
		/* show error/info message or reset status bar*/
		[self showErrorMessage:msg];
	}
}

-(void)onDashboardSaved:(NSString *)dashboardJS version:(uint64_t)version {
	NSArray<NSNumber *> *selectedIDs = (self.editMode ? [self.dashboard objectIDsForIndexPaths:self.selectedItems] : nil);
	NSDictionary * resultInfo = [self.dashboard setDashboard:dashboardJS version:version];
	/* the position of selected items might have changed: */
	if (self.editMode && selectedIDs.count > 0) {
		[self setSelectionForObjects:selectedIDs];
	}
	BOOL dashboardUpdate = [[resultInfo helNumberForKey:@"dashboard_new"] boolValue];
	if (dashboardUpdate) {
		/* dashboard update? deliver all messages (cached and new messages) */
		[self deliverMessages:[NSDate dateWithTimeIntervalSince1970:0L] seqNo:0 notify:NO];
		[self.collectionView reloadData];
		[self showErrorMessage:@"Dashboard has been saved."];
	}
}

/* returns true, if an operation e.g. delete items is active and has not yet completed */
-(BOOL)isOperationActive {
	return (self.progressBar); // delete operation (=save dashboard)
}

-(void)setSelectionForObjects:(NSArray<NSNumber *> *)selectedIDS {
	[self.selectedItems removeAllObjects];
	
	NSArray<DashItem *> *items;
	BOOL found;
	for(NSNumber *id_ in selectedIDS) {
		found = NO;
		for(int i = 0; i < self.dashboard.groups.count && !found; i++) {
			if (self.dashboard.groups[i].id_ == [id_ intValue]) {
				[self.selectedItems addObject:@(i)];
				found = YES;
			} else {
				items = [self.dashboard.groupItems objectForKey:@(self.dashboard.groups[i].id_)];
				for(int j = 0; j < items.count && !found; j++) {
					if (items[j].id_ == [id_ intValue]) {
						[self.selectedItems addObject:[NSIndexPath indexPathForRow:j inSection:i]];
						found = YES;
					}
				}
			}
		}
	}
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
		[UIView setAnimationsEnabled:NO];
		[self.collectionView reloadItemsAtIndexPaths:indexPaths];
		[UIView setAnimationsEnabled:YES];

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
						item.lastMsgTimestamp = msg.timestamp;
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
	BOOL filterScript = ![[notif.userInfo helNumberForKey:@"output"] boolValue];
	
	/* still correct dashboard ? then deliver result */
	if (version > 0 && version == self.dashboard.localVersion) {
		uint32_t oid = [[notif.userInfo helNumberForKey:@"id"] unsignedIntValue];
		NSMutableArray * indexPaths = [NSMutableArray new];
		DashItem *item = [self.dashboard getItemForID:oid indexPathArr:indexPaths];

		if (item) {
			BOOL notify = NO;
			if (filterScript) {
				/* notify dash object about update */
				notify = YES;
			} else { // outputscript
				/* if an error occured, do not call publish but notify observers  */
				NSError *error = [notif.userInfo objectForKey:@"error"];
				if (error) {
					notify = YES;
					uint32_t reqID = [[notif.userInfo helNumberForKey:@"publish_request"] unsignedIntValue];
					[self.activeDetailView onPublishRequestFinished:reqID];
				} else {
					/* no topic? only javascript was executed. notify observers */
					if ([Utils isEmpty:item.topic_p]) {
						notify = YES;
					} else {
						DashMessage *msg = [notif.userInfo objectForKey:@"message"];
						if (msg) {
							/* publish */
							[self.connection publishMessageForAccount:self.dashboard.account topic:msg.topic payload:msg.content retain:item.retain_ userInfo:notif.userInfo];
						}
					}
				}
			}
			if (notify) {
				/* notify dash object about update */
				[UIView setAnimationsEnabled:NO];
				[self.collectionView reloadItemsAtIndexPaths:indexPaths];
				[UIView setAnimationsEnabled:YES];

				if (self.activeDetailView) {
					[self.activeDetailView onNewMessage];
				}
			}
		}
	}
}


- (uint32_t)publish:(NSString *)topic payload:(NSData *)payload retain:(BOOL)retain item:(DashItem *)item {
	self.publishReqIDCounter++;
	DashMessage *msg = [[DashMessage alloc] init];
	msg.timestamp = [NSDate date];
	msg.topic = topic;
	msg.content = payload;
	NSMutableDictionary *requestData = [NSMutableDictionary new];
	[requestData setObject:[NSNumber numberWithUnsignedInt:self.publishReqIDCounter] forKey:@"publish_request"];
	[requestData setObject:[NSNumber numberWithUnsignedLongLong:self.dashboard.localVersion] forKey:@"version"];
	[requestData setObject:[NSNumber numberWithUnsignedLong:item.id_] forKey:@"id"];
	[requestData setObject:msg forKey:@"message"];

	/* If an outputscript exists, javascript must be executed. */
	if (![Utils isEmpty:item.script_p]) {
		DashJavaScriptTask *outputJS = [[DashJavaScriptTask alloc]initWithItem:item publishData:msg version:self.dashboard.localVersion account:self.account requestData:requestData];
		
		/* execute java script output script */
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(queue, ^{
			[outputJS execute];
		});
	} else {
		[self.connection publishMessageForAccount:self.dashboard.account topic:topic payload:payload retain:retain userInfo:requestData];

	}
	
	return self.publishReqIDCounter;
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

- (IBAction)actionMore:(id)sender {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[alert addAction:[UIAlertAction actionWithTitle:@"Edit Dashboard" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self onEditMenuItemClicked];
	}]];

	[alert addAction:[UIAlertAction actionWithTitle:@"Messages" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self performSegueWithIdentifier:@"IDShowMessageList" sender:self];
	}]];

	[alert addAction:[UIAlertAction actionWithTitle:@"Manage Images" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self onManageImagesClicked];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Reload" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self onReloadMenuItemClicked];
	}]];
	
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[alert setModalPresentationStyle:UIModalPresentationPopover];
	
	alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
	[self presentViewController:alert animated:YES completion:nil];
}

-(void)onManageImagesClicked {
	UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Dashboard" bundle:nil];
	DashManageImagesController *vc = [storyboard instantiateViewControllerWithIdentifier:@"ManageImages"];

	/* set args */
	vc.parentCtrl = self;
	
	[self.navigationController pushViewController:vc animated:YES];
}

/* this function is called from action sheet edit - so edit mode is always turned on */
-(void)onEditMenuItemClicked {
	/* update toolbar: hide all menu items and add context related menu items */
	
	if (!self.buttonItemsHeaderNonEditMode) {
		self.buttonItemsHeaderNonEditMode = self.navigationItem.rightBarButtonItems;
	}
	if (!self.buttonItemsHeaderEditMode) {
		NSMutableArray *buttons = [NSMutableArray new];
		
		/* create delete and edit item button */
		UIBarButtonItem *editButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"Edit"] style:UIBarButtonItemStylePlain target:self action:@selector(onEditDashItemButtonClicked)];
		UIBarButtonItem *addButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"Add"] style:UIBarButtonItemStylePlain target:self action:@selector(onAddDashItemButtonClicked)];
		[buttons addObject:editButton];
		[buttons addObject:addButton];
		self.buttonItemsHeaderEditMode = buttons;
	}
	if (!self.buttonItemsFooterEditMode) {
		self.buttonItemsFooterEditMode = self.toolbarItems;
	}
	if (!self.buttonItemsFooterNonEditMode) {
		NSMutableArray * buttons = [self.toolbarItems mutableCopy];
		[buttons removeObject:self.listViewButtonItem];
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(onEditDoneButtonClicked)];
		[buttons addObject:doneButton];
		
		UIBarButtonItem *delButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(onDeleteDashItemButtonClicked)];
		[buttons insertObject:delButton atIndex:0];

		
		self.buttonItemsFooterNonEditMode = buttons;
	}
	self.toolbarItems = self.buttonItemsFooterNonEditMode;
	
	[self.navigationItem setHidesBackButton:YES animated:NO];
	self.navigationItem.rightBarButtonItems = self.buttonItemsHeaderEditMode;
	[self.navigationItem setTitle:@"Edit Dashboard"];
	
	self.editMode = YES;
}

-(void)onEditDoneButtonClicked {
	/* back to non-edit mode: restore standard toolbar */
	self.editMode = NO;
	[self.navigationItem setHidesBackButton:NO animated:NO];
	self.navigationItem.rightBarButtonItems = self.buttonItemsHeaderNonEditMode;
	self.toolbarItems = self.buttonItemsFooterEditMode;
	/* clear selection */
	if (self.selectedItems.count > 0) {
		NSMutableArray *selectedItems = [NSMutableArray new];
		NSMutableArray *selectedGroups = [NSMutableArray new];
		for(NSObject *o in self.selectedItems) {
			if ([o isKindOfClass:[NSIndexPath class]]) {
				[selectedItems addObject:o];
			} else if ([o isKindOfClass:[NSNumber class]]) {
				NSNumber * n = (NSNumber *) o;
				[selectedGroups addObject:[NSIndexPath indexPathForRow:0 inSection:[n integerValue]]];
			}
		}
		[self.selectedItems removeAllObjects];
		[UIView setAnimationsEnabled:NO];
		[self.collectionView reloadItemsAtIndexPaths:selectedItems];
		[UIView setAnimationsEnabled:YES];
		
		DashGroupItemViewCell *groupView;
		DashGroupItem *groupItem;
		for(NSIndexPath *idx in selectedGroups) {
			groupView = (DashGroupItemViewCell *) [self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:idx];
			if (groupView) {
				groupItem = [self.dashboard.groups objectAtIndex:idx.section];
				[groupView onBind:groupItem layoutInfo:((DashCollectionFlowLayout *) self.collectionViewLayout).layoutInfo pos:idx account:self.account selected:NO];
			}
			
		}
	}
	[self.navigationItem setTitle:@"Dashboard"];
}

-(void)onAddDashItemButtonClicked {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Dash" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[alert addAction:[UIAlertAction actionWithTitle:@"Text View" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self showDashItemEditor:Add item:[DashTextItem new]];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Button/Switch" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self showDashItemEditor:Add item:[DashSwitchItem new]];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Progress Bar/Slider" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self showDashItemEditor:Add item:[DashSliderItem new]];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Option List" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self showDashItemEditor:Add item:[DashOptionItem new]];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Custom View" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self showDashItemEditor:Add item:[DashCustomItem new]];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Group" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self showDashItemEditor:Add item:[DashGroupItem new]];
	}]];

	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[alert setModalPresentationStyle:UIModalPresentationPopover];
	
	alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.lastObject;
	[self presentViewController:alert animated:YES completion:nil];
}
-(void)showDashItemEditor:(Mode) mode item:(DashItem *) item {
	if ([self checkIfUpdateRequired]) {
		//do not allow editing if current dashboard was created with a newer app version
		return;
	}
	if ([self isOperationActive]) {
		// do not allow add/edit whil operation active
		[self showErrorMessage:@"Please wait until current action has been finished."];
		return;
	}
	
	self.argEditMode = mode;
	self.argEditItem = item;

	if ([item isKindOfClass:[DashGroupItem class]]) {
		[self performSegueWithIdentifier:@"IDShowEditGroupItemView" sender:self];
	} else if ([item isKindOfClass:[DashTextItem class]]) {
		[self performSegueWithIdentifier:@"IDShowEditTextItemView" sender:self];
	} else if ([item isKindOfClass:[DashOptionItem class]]) {
		[self performSegueWithIdentifier:@"IDShowEditOptionItemView" sender:self];
	} else if ([item isKindOfClass:[DashCustomItem class]]) {
		[self performSegueWithIdentifier:@"IDShowEditCustomItemView" sender:self];
	} else if ([item isKindOfClass:[DashSliderItem class]]) {
		[self performSegueWithIdentifier:@"IDShowEditSliderItemView" sender:self];
	} else if ([item isKindOfClass:[DashSwitchItem class]]) {
		[self performSegueWithIdentifier:@"IDShowEditSwitchItemView" sender:self];
	}
}

-(void)onReloadMenuItemClicked {
	
	// NSMutableArray *list = [NSMutableArray new];
	/* set reload flag for custom items */
	DashGroupItem *groupItem;
	NSIndexPath *p;
	for(int i = 0; i < self.dashboard.groups.count; i++) {
		groupItem = self.dashboard.groups[i];
		NSArray<DashItem *> *items = self.dashboard.groupItems[@(groupItem.id_)];
		for(int j = 0; j < items.count; j++) {
			if ([items[j] isKindOfClass:[DashCustomItem class]]) {
				((DashCustomItem *) items[j]).reloadRequested = YES;
				((DashCustomItem *) items[j]).error1 = @"";
				p = [NSIndexPath indexPathForRow:j inSection:i];
				/* only add if no cached message exist to prevent multiple notificateions */
				// [list addObject:p];
			}
		}
	}
	/* deliver local stored messages*/
	[self deliverMessages:[[NSDate alloc]initWithTimeIntervalSince1970:0] seqNo:0 notify:NO];
	[self.collectionView reloadData];
}

-(void)onEditDashItemButtonClicked {
	if (self.selectedItems.count > 0) {
		NSObject *e = self.selectedItems.lastObject;
		DashItem *item;
		if ([e isKindOfClass:[NSNumber class]]) {
			uint32_t groupIdx = [((NSNumber *) e)unsignedIntValue];
			item = [self.dashboard.groups objectAtIndex:groupIdx];
		} else { // implies
			NSIndexPath *p = (NSIndexPath *) e;
			DashGroupItem *groupItem = [self.dashboard.groups objectAtIndex:p.section];
			NSArray *items = [self.dashboard.groupItems objectForKey:[NSNumber numberWithUnsignedInt:groupItem.id_]];
			item = [items objectAtIndex:p.row];

		}
		item = [self.dashboard getUnmodifiedItemForID:item.id_];
		[self showDashItemEditor:Edit item:item];
	} else {
		[self showErrorMessage:@"No item selected."];
	}
}

-(void)onDeleteDashItemButtonClicked {
	if ([self isOperationActive]) {
		// delete op is active
		[self showErrorMessage:@"Please wait until current action has been finished."];
		return;
	}
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[alert addAction:[UIAlertAction actionWithTitle:@"Delete Selected Items" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self performDeletion:NO];
	}]];
	
	[alert addAction:[UIAlertAction actionWithTitle:@"Delete All Items" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self performDeletion:YES];
	}]];
	
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[alert setModalPresentationStyle:UIModalPresentationPopover];
	
	alert.popoverPresentationController.barButtonItem = self.toolbarItems.firstObject;
	[self presentViewController:alert animated:YES completion:nil];

}
-(void)performDeletion:(BOOL)allItems {
	/* prepare data for saving: clone dashboard */
	
	NSMutableArray<DashGroupItem *> *groups = [NSMutableArray new];
	NSMutableDictionary<NSNumber *, NSArray<DashItem *> *> *groupItems = [NSMutableDictionary new];
	
	if (!allItems) {
		DashGroupItem *group;
		DashItem *item;
		NSNumber *groupIndexPath;
		NSIndexPath *itemIndexPath;
		for(int i = 0; i < self.dashboard.groups.count; i++) {
			/* item values may have changed by script, so get the original item */
			group = (DashGroupItem *) [self.dashboard getUnmodifiedItemForID:self.dashboard.groups[i].id_];
			groupIndexPath = [NSNumber numberWithInteger:i];
			
			NSArray<DashItem *> *items = [self.dashboard.groupItems objectForKey:@(group.id_)];
			NSMutableArray<DashItem *> *modifiedItems = [NSMutableArray new];
			for(int j = 0; j < items.count; j++) {
				item = [self.dashboard getUnmodifiedItemForID:items[j].id_];
				itemIndexPath = [NSIndexPath indexPathForRow:j inSection:i];
				if (![self.selectedItems containsObject:itemIndexPath]) {
					[modifiedItems addObject:item];
				}
			}
			
			/* groups with items will never be deleted. Only if a group is selected and has no (more) items. */
			if (modifiedItems.count > 0 || ![self.selectedItems containsObject:groupIndexPath]) {
				[groups addObject:group];
				[groupItems setObject:modifiedItems forKey:@(group.id_)];
			}
		}
	}
	
	/* prepare data to JSON */
	NSMutableDictionary *dashJson = [Dashboard itemsToJSON:groups items:groupItems];
	[dashJson setObject:@(DASHBOARD_PROTOCOL_VERSION) forKey:@"version"];
	
	/* add locked resources */
	NSMutableArray *lockedResources = [NSMutableArray new];
	for(NSString *r in self.dashboard.resources) {
		if (![Utils isEmpty:r]) {
			[lockedResources addObject:r];
		}
	}
	[dashJson setObject:lockedResources forKey:@"resources"];

	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	[userInfo setObject:[NSNumber numberWithInt:0] forKey:@"save_request"];

	[self.connection saveDashboardForAccount:self.dashboard.account json:dashJson prevVersion:self.dashboard.localVersion itemID:0 userInfo:userInfo];
	[self showProgressBar];
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
	if (self.editMode) {
		if ([self.selectedItems containsObject:indexPath]) {
			[self.selectedItems removeObject:indexPath];
		} else {
			[self.selectedItems addObject:indexPath];
		}
		NSMutableArray *p = [NSMutableArray new];
		[p addObject:indexPath];
		[UIView setAnimationsEnabled:NO];
		[collectionView reloadItemsAtIndexPaths:p];
		[UIView setAnimationsEnabled:YES];
	} else {
		DashItem *group = [self.dashboard.groups objectAtIndex:[indexPath section]];
		NSNumber *key = [NSNumber numberWithUnsignedInt:group.id_];
		DashItem *item = [(NSArray *) [self.dashboard.groupItems objectForKey:key] objectAtIndex:[indexPath row]];
		
		CGRect sourceRect = [collectionView layoutAttributesForItemAtIndexPath:indexPath].frame;
		
		UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Dashboard" bundle:nil];
		DashDetailViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"DashDetailViewController"];
		vc.dashItem = (DashItem *) item;
		vc.dashboard = self.dashboard;
		vc.publishController = self;
		self.activeDetailView = vc;
		
		vc.modalPresentationStyle = UIModalPresentationPopover;
		
		vc.popoverPresentationController.sourceView = collectionView;
		vc.popoverPresentationController.sourceRect = sourceRect;
		
		[self presentViewController:vc animated:YES completion:nil];
	}
}

-(void)onGroupItemSelected:(NSInteger) section {
	if (self.editMode) {
		NSNumber *g = [NSNumber numberWithInteger:section];
		BOOL selected;
		if ([self.selectedItems containsObject:g]) {
			[self.selectedItems removeObject:g];
			selected = NO;
		} else {
			[self.selectedItems addObject:g];
			selected = YES;
		}
		DashGroupItem *groupItem = [self.dashboard.groups objectAtIndex:section];
		NSIndexPath *idx = [NSIndexPath indexPathForRow:0 inSection:g.integerValue];
		DashGroupItemViewCell *groupView = (DashGroupItemViewCell *) [self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:idx];
		
		[groupView onBind:groupItem layoutInfo:((DashCollectionFlowLayout *) self.collectionViewLayout).layoutInfo pos:[NSIndexPath indexPathForRow:0 inSection:section] account:self.account selected:selected];
	}
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	DashCollectionViewCell *cell;
	
	DashItem *group = [self.dashboard.groups objectAtIndex:[indexPath section]];
	NSNumber *key = [NSNumber numberWithUnsignedInt:group.id_];
	DashItem *item = [(NSArray *) [self.dashboard.groupItems objectForKey:key] objectAtIndex:[indexPath row]];
	
	if ([DashCustomItem class] == [item class]) {
		cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDcustomItem forIndexPath:indexPath];
		((DashCustomItemViewCell *) cell).webviewContainer.publishController = self;
	} else if ([DashTextItem class] == [item class]) {
		cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDtextItem forIndexPath:indexPath];
	} else if ([DashSwitchItem class] == [item class]) {
		cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDswitchItem forIndexPath:indexPath];
	} else if ([DashSliderItem class] == [item class]) {
		cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDsliderItem forIndexPath:indexPath];
	} else if ([DashOptionItem class] == [item class]) {
		cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIDoptionItem forIndexPath:indexPath];
	}
	
	BOOL selected = [self.selectedItems containsObject:indexPath];
	[cell onBind:item context:self.dashboard selected:selected];
	
	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	DashGroupItemViewCell *v = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseIGroupItem forIndexPath:indexPath];
	v.groupSelectionHandler = self;
	DashItem *group = [self.dashboard.groups objectAtIndex:[indexPath section]];
	
	NSNumber *idx = [NSNumber numberWithInteger:indexPath.section];
	BOOL selected = [self.selectedItems containsObject:idx];
	// layout info needed in layout pass (only for header)
	[v onBind:group layoutInfo:((DashCollectionFlowLayout *) self.collectionViewLayout).layoutInfo pos:indexPath account:self.account selected:selected];
	
	return v;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {
	
	DashCollectionFlowLayout *layout = (DashCollectionFlowLayout *) collectionViewLayout;
	CGSize size;
	if (section == 0) {
		size = CGSizeMake(layout.headerReferenceSize.width, layout.headerReferenceSize.height + layout.layoutInfo.accountLabelHeight);
	} else {
		size = layout.headerReferenceSize;
	}
	return size;
}

-(void)dealloc {
}

@end
