/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>

@interface DashCollectionViewLayoutInfo : NSObject
@property CGFloat marginLR;
@end

@interface DashCollectionFlowLayout : UICollectionViewFlowLayout
// calculated margin (differs for each zoom level because tiles are centered);
@property DashCollectionViewLayoutInfo *layoutInfo;
@property int zoomLevel;
@property CGFloat labelHeight;

-(void)zoom;
@end



