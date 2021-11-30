/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashColorChooser.h"
#import "DashConsts.h"
#import "DashColorCell.h"

@interface DashColorChooser ()
@property NSArray<UIColor *> *colors;
@end

@implementation DashColorChooser

static NSString * const reuseIdentifier = @"colorCell";
static int64_t colorConsts[] = {DASH_COLOR_WHITE,DASH_COLOR_LT_GRAY,DASH_COLOR_DK_GRAY,DASH_COLOR_BLACK,DASH_COLOR_TAN,DASH_COLOR_YELLOW,DASH_COLOR_ORANGE,DASH_COLOR_RED,DASH_COLOR_BROWN,DASH_COLOR_LT_GREEN,DASH_COLOR_GREEN,DASH_COLOR_PINK,DASH_COLOR_PURPLE,DASH_COLOR_CYAN,DASH_COLOR_LT_BLUE,DASH_COLOR_BLUE};

- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSMutableArray *colors = [NSMutableArray new];
	[colors addObject:self.defaultColor];
	if (self.showClearColor) {
		[colors addObject:[UIColor clearColor]];
	}
	int n = sizeof(colorConsts)/sizeof(colorConsts[0]);
	for(int i = 0; i < n; i++) {
		[colors addObject:UIColorFromRGB(colorConsts[i])];
	}
	self.colors = colors;
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.colors.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DashColorCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
	
	cell.colorButton.fillColor = self.colors[indexPath.row];
	cell.colorButton.clearColor = self.showClearColor && indexPath.row == 1;
	if (indexPath.row == 0) {
		CGFloat h,s,b,a;
		UIColor *titleColor;
		[cell.colorButton.fillColor getHue:&h saturation:&s brightness:&b alpha:&a];
		if (b < .25f) {
			titleColor = [UIColor whiteColor];
		} else {
			titleColor = [UIColor blackColor];
		}
		[cell.colorButton setTitleColor:titleColor forState:UIControlStateNormal];
		[cell.colorButton setTitle:@"Default" forState:UIControlStateNormal];
		
	} else {
		[cell.colorButton setTitle:nil forState:UIControlStateNormal];
	}
	[cell.colorButton addTarget:self action:@selector(onColorButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

-(void)onColorButtonClicked:(UIButton *)button {
	UIView *parent = [button superview];
	while(parent) {
		if ([parent isKindOfClass:[DashColorCell class]]) {
			NSIndexPath *p = [self.collectionView indexPathForCell:(DashColorCell *) parent];
			int64_t selectedColor;
			if (p.row == 0) {
				selectedColor = DASH_COLOR_OS_DEFAULT;
			} else if (self.showClearColor && p.row == 1) {
				selectedColor = DASH_COLOR_CLEAR;
			} else {
				int idx = (int) p.row - 1;
				if (self.showClearColor) {
					idx--;
				}
				selectedColor = colorConsts[idx];
			}
			[self.parentCtrl onColorChanged:self.srcButton color:selectedColor];
			[self performSegueWithIdentifier:@"IDExitColorChooser" sender:self];
			break;
		}
		parent = [parent superview];
	}
}

@end
