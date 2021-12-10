/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashImageChooserTab.h"
#import "DashConsts.h"
#import "DashUtils.h"
#import "DashEditOptionViewController.h"
#import "NSString+HELUtils.h"


@interface DashImageChooserTab ()
@property UIColor *noneLabelTextColor;
@property UIColor *imageTintColor; // only for internal images
@property UIColor *highLightColor;
@property BOOL internal;
/* valid resource names */
@property NSArray<NSString *> *resoureNames;
/* row -> UIImage|NSOperation: if value is an NSOperation object, the loading is currently in progress */
@property NSMutableDictionary<NSNumber *, NSObject *> *resourceMap;
@property NSOperationQueue* operationQueue;
@end

@implementation DashImageChooserTab

static NSString * const reuseIdentifierNone = @"noneCell";
static NSString * const reuseIdentifierImage = @"imageCell";

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.noneLabelTextColor = [UIButton buttonWithType:UIButtonTypeSystem].titleLabel.textColor;
	self.highLightColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.3];
	
	self.internal = ((UITabBarController *) self.parentViewController).viewControllers.firstObject == self;
	self.imageTintColor = [UIColor darkGrayColor]; //TODO: dark mode
	NSMutableArray *res = [NSMutableArray new];
	if (self.internal) {
		[self addInternalResourceNames:res];
	} else {
		[self addExternalResourceNames:res];
	}
	self.resourceMap = [NSMutableDictionary new];
	self.resoureNames = res;
	self.operationQueue = [[NSOperationQueue alloc] init];
	self.operationQueue.maxConcurrentOperationCount = 2;
	self.collectionView.prefetchDataSource = self;
}

#pragma mark <UICollectionViewDataSourcePrefetching>

-(void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
	NSInvocationOperation *op;
	for(NSIndexPath *p in indexPaths) {
		if (p.row == 0) {
			continue;
		}
		id resource = self.resourceMap[@(p.row - 1)];
		if (!resource) {
			op = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(loadImage:) object:p];
			[self.resourceMap setObject:op forKey:@(p.row - 1)];
			[self.operationQueue addOperation:op];
		}
		
	}
}

- (void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
	NSObject *val;
	for(NSIndexPath *p in indexPaths) {
		if (p.row > 0) {
			val = self.resourceMap[@(p.row - 1)];
			if ([val isKindOfClass:[NSOperation class]]) {
				[((NSOperation *) val) cancel];
				[self.resourceMap removeObjectForKey:@(p.row - 1)];
			}
		}
	}
}

-(void)loadImage:(NSIndexPath *)indexPath {
	
	NSString *resourceName = self.resoureNames[indexPath.row - 1];
	NSString *uri;
	if ([resourceName hasPrefix:@"tmp/"]) {
		uri = [DashUtils buildResourceURI:@"imported" resourceName:[resourceName substringFromIndex:4]];
	} else if (self.internal) {
		uri = [DashUtils buildResourceURI:@"internal" resourceName:resourceName];
	} else {
		uri = [DashUtils buildResourceURI:@"user" resourceName:resourceName];
	}
	
	UIImage *img = [DashUtils loadImageResource:uri userDataDir:self.context.account.cacheURL];
	if (self.internal) {
		img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	}

	NSMutableDictionary *args = [NSMutableDictionary new];
	[args setObject:img forKey:@"image"];
	[args setObject:indexPath forKey:@"indexPath"];

	[self performSelectorOnMainThread:@selector(notifyUpdate:) withObject:args waitUntilDone:NO];
}

-(void)notifyUpdate:(NSDictionary *)data {
	NSIndexPath *idx = data[@"indexPath"];
	[self.resourceMap setObject:data[@"image"] forKey:@(idx.row - 1)];
	NSMutableArray *args = [NSMutableArray new];
	[args addObject:idx];
	[self.collectionView reloadItemsAtIndexPaths:args];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.resoureNames.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell;
	if (indexPath.row == 0) {
		cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifierNone forIndexPath:indexPath];
		NSArray * subviews = [cell.contentView subviews];
		if (subviews.count > 0 && [subviews.firstObject isKindOfClass:[UILabel class]]) {
			((UILabel *) [subviews firstObject]).textColor = self.noneLabelTextColor;
		}
	} else {
		DashImageChooserCell *icell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifierImage forIndexPath:indexPath];
		UIImage *img = nil;

		id resource = self.resourceMap[@(indexPath.row - 1)];
		if ([resource isKindOfClass:[NSInvocationOperation class]]) {
			/* loading in progress but no result yet */
			img = nil;
		} else if (!resource) {
			img = nil;
			/* request image */
			NSMutableArray *args = [NSMutableArray new];
			[args addObject:indexPath];
			[self.collectionView.prefetchDataSource collectionView:collectionView prefetchItemsAtIndexPaths:args];
		} else {
			/* image has been loaded */
			img = resource;
		}
		
		icell.imageView.image = img;
		if (self.internal) {
			icell.imageView.tintColor = self.imageTintColor;
		}
		icell.label.text = self.resoureNames[indexPath.row - 1];
		cell = icell;
	}
	
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
	cell.contentView.backgroundColor = self.highLightColor;
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
	cell.contentView.backgroundColor = nil;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	NSString *uri;
	if (indexPath.row == 0) {
		uri = nil;
	} else {
		NSString *resourceName = self.resoureNames[indexPath.row - 1];
		if ([resourceName hasPrefix:@"tmp/"]) {
			uri = [DashUtils buildResourceURI:@"imported" resourceName:[resourceName substringFromIndex:4]];
		} else if (self.internal) {
			uri = [DashUtils buildResourceURI:@"internal" resourceName:resourceName];
		} else {
			uri = [DashUtils buildResourceURI:@"user" resourceName:resourceName];
		}
	}
	if ([self.editor isKindOfClass:[DashEditItemViewController class]]) {
		[(DashEditItemViewController *) self.editor onImageSelected:self.sourceButton imageURI:uri];
		[self performSegueWithIdentifier:@"IDExitImageChooser" sender:self];
	} else if ([self.editor isKindOfClass:[DashEditOptionViewController class]]) {
		[(DashEditOptionViewController *) self.editor onImageSelected:uri];
		[self performSegueWithIdentifier:@"IDExitImageChooserOptionItem" sender:self];
	}
}

-(void)addExternalResourceNames:(NSMutableArray *) res {
	//TODO: consider moving to DashUtils
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL* dir = [self.context.account.cacheURL URLByAppendingPathComponent:LOCAL_USER_FILES_DIR isDirectory:YES];
	NSDirectoryEnumerator *dirEnum = [fm enumeratorAtURL:dir includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil];

	NSMutableArray *filenames = [NSMutableArray new];
	NSString *file, *filename;
	while ((file = [dirEnum nextObject])) {
		if ([[file pathExtension] isEqualToString:DASH512_PNG]) {
			filename = [[file.lastPathComponent stringByDeletingPathExtension] dequoteHelios];
			[filenames addObject:filename];
		}
	}
	NSArray *sortedFilenames = [filenames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	[res addObjectsFromArray:sortedFilenames];
	
	/* imported files */
	[filenames removeAllObjects];
	NSURL* importDir = [self.context.account.cacheURL URLByAppendingPathComponent:LOCAL_IMPORTED_FILES_DIR isDirectory:YES];
	dirEnum = [fm enumeratorAtURL:importDir includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil];
	while ((file = [dirEnum nextObject])) {
		if ([[file pathExtension] isEqualToString:DASH512_PNG]) {
			filename = [[file.lastPathComponent stringByDeletingPathExtension] dequoteHelios];
			[filenames addObject:[NSString stringWithFormat:@"tmp/%@",filename]];
		}
	}
	sortedFilenames = [filenames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	[res addObjectsFromArray:sortedFilenames];
}

-(void)addInternalResourceNames:(NSMutableArray *) res {
	// toggle
	[res addObject:@"toggle_on"];
	[res addObject:@"toggle_off"];
	[res addObject:@"check_box"];
	[res addObject:@"check_box_outline_blank"];
	[res addObject:@"indeterminate_check_box"];
	[res addObject:@"radio_button_checked"];
	[res addObject:@"radio_button_unchecked"];
	[res addObject:@"lock"];
	[res addObject:@"lock_open"];
	[res addObject:@"notifications_active"];
	[res addObject:@"notifications_off"];
	[res addObject:@"videocam"];
	[res addObject:@"videocam_off"];
	[res addObject:@"signal_wifi_4_bar"];
	[res addObject:@"signal_wifi_off"];
	[res addObject:@"wifi"];
	[res addObject:@"wifi_off"];
	[res addObject:@"alarm_on"];
	[res addObject:@"alarm_off"];
	[res addObject:@"timer"];
	[res addObject:@"timer_off"];
	[res addObject:@"airplanemode_active"];
	[res addObject:@"airplanemode_inactive"];
	[res addObject:@"visibility"];
	[res addObject:@"visibility_off"];
	[res addObject:@"phone_enabled"];
	[res addObject:@"phone_disabled"];
	[res addObject:@"thumb_down"];
	[res addObject:@"thumb_up"];
	
	// msic
	[res addObject:@"check_circle"];
	[res addObject:@"check_circle_outline"];
	[res addObject:@"send"];
	[res addObject:@"clear"];
	[res addObject:@"mail"];
	[res addObject:@"vpn_key"];
	[res addObject:@"rss_feed"];
	[res addObject:@"ac_unit"];
	[res addObject:@"emoji_objects"];
	[res addObject:@"wb_incandescent"];
	[res addObject:@"wb_sunny"];
	[res addObject:@"error"];
	[res addObject:@"error_outline"];
	[res addObject:@"house"];
	[res addObject:@"warning"];
	[res addObject:@"not_interested"];
	[res addObject:@"update"];
	[res addObject:@"access_alarms"];
	[res addObject:@"access_time"];
	[res addObject:@"security"];
	[res addObject:@"battery_alert"];
	[res addObject:@"battery_full"];
	
	// alarm
	[res addObject:@"notifications"];
	[res addObject:@"notifications_none"];
	[res addObject:@"notifications_paused"];
	[res addObject:@"add_alert"];
	[res addObject:@"notification_important"];
	
	// AV
	[res addObject:@"forward_10"];
	[res addObject:@"forward_30"];
	[res addObject:@"forward_5"];
	[res addObject:@"pause_circle_filled"];
	[res addObject:@"pause_circle_outline"];
	[res addObject:@"play_arrow"];
	[res addObject:@"play_circle_filled"];
	[res addObject:@"play_circle_outline"];
	[res addObject:@"replay"];
	[res addObject:@"replay_10"];
	[res addObject:@"replay_30"];
	[res addObject:@"replay_5"];
	[res addObject:@"volume_down"];
	[res addObject:@"volume_mute"];
	[res addObject:@"volume_off"];
	[res addObject:@"volume_up"];
	
	// emojis
	[res addObject:@"sentiment_dissatisfied"];
	[res addObject:@"sentiment_satisfied"];
	[res addObject:@"sentiment_very_dissatisfied"];
	[res addObject:@"sentiment_very_satisfied"];
}

@end

@implementation DashImageChooserCell

@end
