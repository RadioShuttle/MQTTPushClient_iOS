/*
 * Copyright (c) 2022 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashManageImagesController.h"
#import "DashConsts.h"
#import "NSString+HELUtils.h"
#import "DashImageCell.h"
#import "DashUtils.h"

@interface DashManageImagesController ()

/* valid resource names */
@property NSMutableArray<NSString *> *resoureNames;
@property NSMutableSet<NSString *> *lockedResources;

/* row -> UIImage|NSOperation: if value is an NSOperation object, the loading is currently in progress */
@property NSMutableDictionary<NSNumber *, NSObject *> *resourceMap;
@property NSOperationQueue* operationQueue;

@end

@implementation DashManageImagesController

static NSString * const reuseIdentifierImage = @"imageCell";

- (void)viewDidLoad {
    [super viewDidLoad];

	self.resoureNames = [NSMutableArray new];
	[self addExternalResourceNames:self.resoureNames];
	self.lockedResources = [NSMutableSet new];
	if (self.context.resources) {
		[self.lockedResources addObjectsFromArray:self.context.resources];
	}
	
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
	
	id resource = self.resourceMap[@(indexPath.row)];
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
	cell.label.text = self.resoureNames[indexPath.row];
	
	NSString *type;
	NSString *fileName;
	NSString *uri;
	if ([cell.label.text hasPrefix:@"tmp/"]) {
		type = @"imported";
		fileName = [cell.label.text substringFromIndex:4];
	} else {
		type = @"user";
		fileName = cell.label.text;
	}
	uri = [DashUtils buildResourceURI:type resourceName:fileName];
	
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
	for(NSIndexPath *p in indexPaths) {
		id resource = self.resourceMap[@(p.row)];
		if (!resource) {
			op = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(loadImage:) object:p];
			[self.resourceMap setObject:op forKey:@(p.row)];
			[self.operationQueue addOperation:op];
		}
	}
}

- (void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
	NSObject *val;
	for(NSIndexPath *p in indexPaths) {
		val = self.resourceMap[@(p.row)];
		if ([val isKindOfClass:[NSOperation class]]) {
			[((NSOperation *) val) cancel];
			[self.resourceMap removeObjectForKey:@(p.row)];
		}
	}
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	if (self.isEditing) {
		NSString *selectedResource = self.resoureNames[indexPath.row];
		NSString *type;
		NSString *fileName;
		NSString *uri;
		if ([selectedResource hasPrefix:@"tmp/"]) {
			type = @"imported";
			fileName = [selectedResource substringFromIndex:4];
		} else {
			type = @"user";
			fileName = selectedResource;
		}
		uri = [DashUtils buildResourceURI:type resourceName:fileName];
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

-(void)loadImage:(NSIndexPath *)indexPath {
	
	NSString *resourceName = self.resoureNames[indexPath.row];
	NSString *uri;
	if ([resourceName hasPrefix:@"tmp/"]) {
		uri = [DashUtils buildResourceURI:@"imported" resourceName:[resourceName substringFromIndex:4]];
	} else {
		uri = [DashUtils buildResourceURI:@"user" resourceName:resourceName];
	}
	
	UIImage *img = [DashUtils loadImageResource:uri userDataDir:self.context.account.cacheURL];
	
	NSMutableDictionary *args = [NSMutableDictionary new];
	[args setObject:img forKey:@"image"];
	[args setObject:indexPath forKey:@"indexPath"];
	
	[self performSelectorOnMainThread:@selector(notifyUpdate:) withObject:args waitUntilDone:NO];
}

-(void)notifyUpdate:(NSDictionary *)data {
	NSIndexPath *idx = data[@"indexPath"];
	[self.resourceMap setObject:data[@"image"] forKey:@(idx.row)];
	NSMutableArray *args = [NSMutableArray new];
	[args addObject:idx];
	[self.collectionView reloadItemsAtIndexPaths:args];
}

#pragma mark <UICollectionViewDelegate>

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

-(BOOL)hasModified {
	//TODO:
	return NO;
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

-(void)onImportButtonClicked {
}

@end
