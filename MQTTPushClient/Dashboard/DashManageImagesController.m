/*
 * Copyright (c) 2022 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashManageImagesController.h"
#import "DashConsts.h"
#import "NSString+HELUtils.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "DashImageCell.h"
#import "DashUtils.h"
#import "Utils.h"

@import Photos;

@interface DashManageImagesController ()

/* valid resource names */
@property NSMutableArray<NSString *> *resoureNames;
/* locked resource uris */
@property NSMutableSet<NSString *> *lockedResources;
@property NSSet<NSString *> *lockedResourcesOrg;

/* resource uri -> UIImage|NSOperation: if value is an NSOperation object, the loading is currently in progress */
@property NSMutableDictionary<NSString *, NSObject *> *resourceMap;
@property NSOperationQueue* operationQueue;

@property uint64_t dashboardVersion;
@property uint32_t saveRequestID;
@property UIActivityIndicatorView *progressBar;
@property NSTimer *statusMsgTimer;

@property UIImagePickerController *imagePicker;

@end

@implementation DashManageImagesController

static NSString * const reuseIdentifierImage = @"imageCell";

- (void)viewDidLoad {
    [super viewDidLoad];

	self.resoureNames = [NSMutableArray new];
	[self addExternalResourceNames:self.resoureNames];
	self.lockedResources = [NSMutableSet new];
	if (self.parentCtrl.dashboard.resources) {
		[self.lockedResources addObjectsFromArray:self.parentCtrl.dashboard.resources];
	}
	self.lockedResourcesOrg = [self.lockedResources copy];
	
	self.resourceMap = [NSMutableDictionary new];
	self.operationQueue = [[NSOperationQueue alloc] init];
	self.operationQueue.maxConcurrentOperationCount = 2;
	self.collectionView.prefetchDataSource = self;
	
	self.cancelButton.target = self;
	self.cancelButton.action = @selector(onCancelButtonClicked);
	
	self.saveButton.target = self;
	self.saveButton.action = @selector(onSaveButtonClicked);
	
	self.moreButton.target = self;
	self.moreButton.action = @selector(onMoreButtonClicked);
	
	NSMutableArray *toolbarItems = [self.toolbarItems mutableCopy];
	[toolbarItems addObject:self.editButtonItem];
	self.toolbarItems = toolbarItems;
	
	self.dashboardVersion = self.parentCtrl.dashboard.localVersion;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSaveRequestFinished:) name:@"ServerUpdateNotification" object:self.parentCtrl.connection];
	
}

/* called after an import operation */
-(void)reload {
	/* reread resource names */
	self.resoureNames = [NSMutableArray new];
	[self addExternalResourceNames:self.resoureNames];
	
	[self.collectionView reloadData];
	
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.resoureNames.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	DashImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifierImage forIndexPath:indexPath];
	UIImage *img = nil;
	
	NSString *key = [self resourceURIForIndexPath:indexPath];
	id resource = self.resourceMap[key];
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
	
	cell.imageView.image = img;
	
	/* remove numeric id (prefix) from imported file for display */
	NSString *filteredName = [DashUtils filterResourceName:self.resoureNames[indexPath.row]];
	cell.label.text = filteredName;
	
	NSString *uri = [self resourceURIForIndexPath:indexPath];
	
	if ([self.lockedResources containsObject:uri]) {
		[cell showLock];
	} else {
		[cell hideLock];
	}

    return cell;
}

#pragma mark <UICollectionViewDataSourcePrefetching>

-(void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
	NSInvocationOperation *op;
	NSString *key;
	for(NSIndexPath *p in indexPaths) {
		key = [self resourceURIForIndexPath:p];
		id resource = self.resourceMap[key];
		if (!resource) {
			op = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(loadImage:) object:p];
			[self.resourceMap setObject:op forKey:key];
			[self.operationQueue addOperation:op];
		}
	}
}

- (void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
	NSObject *val;
	NSString *key;
	for(NSIndexPath *p in indexPaths) {
		key = [self resourceURIForIndexPath:p];
		val = self.resourceMap[key];
		if ([val isKindOfClass:[NSOperation class]]) {
			[((NSOperation *) val) cancel];
			[self.resourceMap removeObjectForKey:key];
		}
	}
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	if (self.isEditing) {
		NSString *uri = [self resourceURIForIndexPath:indexPath];
		if (uri) {
			if ([self.lockedResources containsObject:uri]) {
				[self.lockedResources removeObject:uri];
			} else {
				[self.lockedResources addObject:uri];
			}
			NSMutableArray *indexPathArr = [NSMutableArray new];
			[indexPathArr addObject:indexPath];
			[self.collectionView reloadItemsAtIndexPaths:indexPathArr];
		}
	}
}

-(NSString *)resourceURIForIndexPath:(NSIndexPath *)indexPath {
	NSString* uri;
	if (indexPath && indexPath.row < self.resoureNames.count) {
		NSString *selectedResource = self.resoureNames[indexPath.row];
		NSString *type;
		NSString *fileName;
		if ([selectedResource hasPrefix:@"tmp/"]) {
			type = @"imported";
			fileName = [selectedResource substringFromIndex:4];
		} else {
			type = @"user";
			fileName = selectedResource;
		}
		uri = [DashUtils buildResourceURI:type resourceName:fileName];
	}
	return uri;
}

-(void)loadImage:(NSIndexPath *)indexPath {
	
	NSString *resourceName = self.resoureNames[indexPath.row];
	NSString *uri;
	if ([resourceName hasPrefix:@"tmp/"]) {
		uri = [DashUtils buildResourceURI:@"imported" resourceName:[resourceName substringFromIndex:4]];
	} else {
		uri = [DashUtils buildResourceURI:@"user" resourceName:resourceName];
	}
	
	UIImage *img = [DashUtils loadImageResource:uri userDataDir:self.parentCtrl.dashboard.account.cacheURL];
	if (img) {
		NSMutableDictionary *args = [NSMutableDictionary new];
		[args setObject:img forKey:@"image"];
		[args setObject:uri forKey:@"uri"];
		
		[self performSelectorOnMainThread:@selector(notifyUpdate:) withObject:args waitUntilDone:NO];
	}
}

-(void)notifyUpdate:(NSDictionary *)data {
	NSString *key = data[@"uri"];
	[self.resourceMap setObject:data[@"image"] forKey:key];
	NSMutableArray *args = [NSMutableArray new];
	NSString *uri;
	NSIndexPath *idx;
	for(int i = 0; i < self.resoureNames.count; i++) {
		idx = [NSIndexPath indexPathForItem:i inSection:0];
		uri = [self resourceURIForIndexPath:idx];
		if ([key isEqualToString:uri]) {
			[args addObject:idx];
			[self.collectionView reloadItemsAtIndexPaths:args];
			break;
		}
	}
}

#pragma mark <UICollectionViewDelegate>

-(void)addExternalResourceNames:(NSMutableArray *) res {
	//TODO: consider moving to DashUtils
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL* dir = [self.parentCtrl.dashboard.account.cacheURL URLByAppendingPathComponent:LOCAL_USER_FILES_DIR isDirectory:YES];
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
	NSURL* importDir = [self.parentCtrl.dashboard.account.cacheURL URLByAppendingPathComponent:LOCAL_IMPORTED_FILES_DIR isDirectory:YES];
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

-(BOOL)hasModified {
	return ![self.lockedResourcesOrg isEqualToSet:self.lockedResources];
}

-(void)onCancelButtonClicked {
	if ([self hasModified]) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Go back without saving?" message:@"Data has been modified." preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self performSegueWithIdentifier:@"IDExitManageImages" sender:nil];
		}]];
		[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		}]];
		[self presentViewController:alert animated:TRUE completion:nil];
	} else {
		[self performSegueWithIdentifier:@"IDExitManageImages" sender:nil];
	}
}

-(void)onSaveButtonClicked {
	if (self.saveRequestID > 0) {
		[self setStatusMessage:@"A save operation is currently in progress." clearAfterDelay:YES];
		return;
	} else if (self.dashboardVersion != self.parentCtrl.dashboard.localVersion) {
		[self setStatusMessage:@"Version error. Quit the editor to update to the latest version." clearAfterDelay:NO];
		return;
	}
	
	if (![self hasModified]) {
		[self setStatusMessage:@"Data was not modified." clearAfterDelay:YES];
	} else {

 		/* prepare data for saving: clone dashboard */
		NSMutableArray<DashGroupItem *> *groups = [self.parentCtrl.dashboard.groups mutableCopy];
		NSMutableDictionary<NSNumber *, NSArray<DashItem *> *> *groupItems = [self.parentCtrl.dashboard.groupItems mutableCopy];
		/* item values may have changed by script, so get the original item */
		for(int i = 0; i < groups.count; i++) {
			groups[i] = (DashGroupItem *) [self.parentCtrl.dashboard getUnmodifiedItemForID:groups[i].id_];
			NSMutableArray<DashItem *> *items = [[groupItems objectForKey:@(groups[i].id_)] mutableCopy];
			[groupItems setObject:items forKey:@(groups[i].id_)];
			for(int j = 0; j < items.count; j++) {
				items[j] = [self.parentCtrl.dashboard getUnmodifiedItemForID:items[j].id_];
			}
		}
		
		/* prepare data to JSON */
		NSMutableDictionary *dashJson = [Dashboard itemsToJSON:groups items:groupItems];
		[dashJson setObject:@(DASHBOARD_PROTOCOL_VERSION) forKey:@"version"];
		
		/* add locked resources */
		NSMutableArray *lockedResources = [NSMutableArray new];
		for(NSString *r in self.lockedResources) {
			if (![Utils isEmpty:r]) {
				[lockedResources addObject:r];
			}
		}
		[dashJson setObject:lockedResources forKey:@"resources"];

		NSMutableDictionary *userInfo = [NSMutableDictionary new];
		self.saveRequestID = ++self.parentCtrl.saveRequestCnt;
		[userInfo setObject:[NSNumber numberWithInt:self.saveRequestID] forKey:@"save_request"];
		
		[self.parentCtrl.connection saveDashboardForAccount:self.parentCtrl.dashboard.account json:dashJson prevVersion:self.parentCtrl.dashboard.localVersion itemID:0 userInfo:userInfo];
		[self showProgressBar];
	}
}

-(void)onMoreButtonClicked {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[alert addAction:[UIAlertAction actionWithTitle:@"Import" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self onImportButtonClicked];
	}]];
	
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[alert setModalPresentationStyle:UIModalPresentationPopover];
	
	alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
	[self presentViewController:alert animated:TRUE completion:nil];

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

-(void)setStatusMessage:(NSString *) msg clearAfterDelay:(BOOL)clearAfterDelay {
	if (self.statusMsgTimer) {
		[self.statusMsgTimer invalidate];
	}
	self.statusBarLabel.text = msg;
	if (clearAfterDelay) {
		self.statusMsgTimer = [NSTimer scheduledTimerWithTimeInterval:5 repeats:NO block:^(NSTimer * _Nonnull timer){self.statusBarLabel.text = nil; }];
	}
}

-(void)onImportButtonClicked {
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
		[self setStatusMessage:@"The photo library is not available." clearAfterDelay:YES];
		return;
	}
	
	PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
	
	if (status == PHAuthorizationStatusDenied) {
		[self setStatusMessage:@"The access to photo library has been denied." clearAfterDelay:YES];
		return;
	} else if (status == PHAuthorizationStatusNotDetermined) {
		 // Access has not been determined.
		 [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
			 if (status == PHAuthorizationStatusAuthorized) {
				 // Access has been granted.
			 }
			 else {
				 // Access has been denied.
			 }
		 }];
	}
	self.imagePicker = [[UIImagePickerController alloc] init];
	self.imagePicker.delegate = self;
	// self.imagePicker.allowsEditing = YES;
	self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	[self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
	
	if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
		[self setStatusMessage:@"The access to photo library is not authorized" clearAfterDelay:YES];
		return;
	}
	
	NSString *filename;
	PHAsset *asset;
	
	if (@available(iOS 11, *)) {
		asset = info[UIImagePickerControllerPHAsset]; //TODO: phppickerviewcontroller since iOS 14
		if (asset) {
			NSArray *resources = [PHAssetResource assetResourcesForAsset:asset];
			filename = [resources.firstObject originalFilename].lastPathComponent;
			// NSLog(@"Filename 2: %@", filename);
		}
	} else {
		NSURL *u = info[UIImagePickerControllerReferenceURL];
		if (u) {
			NSMutableArray *urls = [NSMutableArray new];
			[urls addObject:u];
			PHFetchResult<PHAsset *> * result = [PHAsset fetchAssetsWithALAssetURLs:urls options:nil];
			asset = result.firstObject;
			if (asset) {
				NSArray<PHAssetResource *> *assetRes = [PHAssetResource assetResourcesForAsset:asset];
				filename = assetRes.firstObject.originalFilename;
				// NSLog(@"Filename 1: %@", filename);
			}
		}
	}
	
	if (!asset) { // should not happen, but who knows
		[self setStatusMessage:@"Import error." clearAfterDelay:YES];
		return;
	}
	
	/* all imported files have a prefix which is unique in import dir. get max id: */
	NSURL *dirURL = [DashUtils getImportedFilesDir:self.parentCtrl.dashboard.account.cacheURL];
	NSArray* content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirURL.path error:nil];
	int maxPrefixID = -1, uniquePrefixID;
	for(NSString *fn in content) {
		uniquePrefixID = [DashUtils getImportedFilePrefix:fn];
		if (uniquePrefixID > maxPrefixID) {
			maxPrefixID = uniquePrefixID;
		}
	}
	maxPrefixID++;

	CGSize s = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
	
	if (s.height > DASH_MAX_IMAGE_SIZE_PX || s.width > DASH_MAX_IMAGE_SIZE_PX) {
		int heightRatio = round(s.width / (CGFloat) DASH_MAX_IMAGE_SIZE_PX);
		int widthRatio = round(s.height / (CGFloat) DASH_MAX_IMAGE_SIZE_PX);
		
		int sampleSize = heightRatio > widthRatio ? heightRatio : widthRatio;
		if (sampleSize > 1) {
			s = CGSizeMake(s.width / sampleSize, s.height / sampleSize);
		}
	}
	
	PHImageRequestOptions *opts = [PHImageRequestOptions new];
	opts.synchronous = NO;
	opts.resizeMode = PHImageRequestOptionsResizeModeFast;
	opts.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;

	if ([Utils isEmpty:filename]) {
		filename = @"image";
	}
	filename = [[filename stringByDeletingPathExtension] enquoteHelios];
	filename = [NSString stringWithFormat:@"%d_%@.%@", maxPrefixID, filename, DASH512_PNG];
	NSURL *localDir = [DashUtils getImportedFilesDir:self.parentCtrl.dashboard.account.cacheURL];
	NSURL *fileURL = [DashUtils appendStringToURL:localDir str:filename];
	
	[[PHImageManager defaultManager] requestImageForAsset:asset targetSize:s contentMode:PHImageContentModeAspectFit options:opts resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
		if ([[info helNumberForKey:PHImageResultIsDegradedKey] boolValue]) {
			;
		} else {
			BOOL ok = NO;
			if (result) {
				if ([UIImagePNGRepresentation(result) writeToURL:fileURL atomically:YES]) {
					[self reload];
					ok = YES;
				}
			}
			if (!ok) {
				[self setStatusMessage:@"Import failed." clearAfterDelay:NO];
			}
		}
	}];

	
	[self.imagePicker dismissViewControllerAnimated:YES completion:nil];
}

@end
