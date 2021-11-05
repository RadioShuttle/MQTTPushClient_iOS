//
//  DashCollectionFlowLayout.m
//  BigApp
//
//  Created by Adalbert Winkler on 14.07.21.
//  Copyright © 2021 Adalbert Winkler. All rights reserved.
//

#import "DashCollectionFlowLayout.h"
#import "DashConsts.h"

@implementation DashCollectionFlowLayout

- (instancetype)init {
    if (self = [super init]) {
        // Initialize self
        self.layoutInfo = [DashCollectionViewLayoutInfo new];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.layoutInfo = [DashCollectionViewLayoutInfo new];
		self.layoutInfo.accountLabelHeight = 24.0f;
    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];
    
    if (self.collectionView) {

        CGFloat a;
        switch (self.zoomLevel) {
            case 2:
                a = DASH_ZOOM_2;
                break;
            case 3:
                a = DASH_ZOOM_3;
                break;
            default:
                self.zoomLevel = 1;
                a = DASH_ZOOM_1;
                break;
        }

        CGFloat minMarginLR = 16.0f;
        CGFloat minIntSpacing = 10.0f;

        UIEdgeInsets margins = self.collectionView.layoutMargins;
        CGFloat w = self.collectionView.bounds.size.width - (margins.right - margins.left);
        
        
        CGFloat w2 = w - minMarginLR * 2.0f; // subtract min left and right margin
        int spanCount = (int) (w2 / a); // no of cells per row
        if (spanCount > 1) {
            CGFloat sp = (spanCount - 1) * minIntSpacing;
            if (sp + spanCount * a > w2) {
                spanCount--; // not enough space with minimumInteritemSpacing -> decrease span count
            }
        }
        // calc margin to add to section inset, so tiles row will be centered
        CGFloat addToMarginLR = (w2 - (spanCount * a + (spanCount - 1) * minIntSpacing)) / 2.0f;
        
        self.minimumInteritemSpacing = minIntSpacing;
        //t, l, b, r
        self.layoutInfo.marginLR = addToMarginLR + minMarginLR;
        self.sectionInset = UIEdgeInsetsMake(10.0f, self.layoutInfo.marginLR, 10.0f, self.layoutInfo.marginLR);
        
        // item size
        self.itemSize = CGSizeMake(a,a + self.labelHeight);
    }
}


-(void)zoom {
    self.zoomLevel++;
    if (self.zoomLevel > 3) {
        self.zoomLevel = 1;
    } else if (self.zoomLevel == 1) {
        self.zoomLevel = 2;
    }
    [self invalidateLayout];
}

@end

@implementation DashCollectionViewLayoutInfo

@end
