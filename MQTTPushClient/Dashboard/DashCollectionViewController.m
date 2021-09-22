/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCollectionViewController.h"
#import "MessageListTableViewController.h"
#import "Connection.h"
#import "Utils.h"
#import "DashConsts.h"

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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNewDashboardDataReceived:) name:@"DashboardDataUpdateNotification" object:self.dashboard];
	[self startTimer];
}

- (void)viewWillDisappear:(BOOL)a {
	[super viewWillDisappear:a];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self stopTimer];
}

- (void)onRequestFinished:(NSNotification *)aNotification {
	if (self.account.error) {
		self.statusBarLabel.text = self.account.error.localizedDescription;
	} else {
		self.statusBarLabel.text = @"";
	}
}

/* new Dashboard and/or new messages and resources */
- (void)onNewDashboardDataReceived:(NSNotification *)aNotification {
	
	//TODO: remove
	NSDictionary* userInfo = aNotification.userInfo;
	NSEnumerator *enumerator = [userInfo keyEnumerator];
	id key;
	while ((key = [enumerator nextObject])) {
		NSLog(@"key: %@ value: %@", key, userInfo[key]);
	}
	// end remove
	if (userInfo[@"dashboard_new"]) {
		[self.collectionView reloadData];
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
