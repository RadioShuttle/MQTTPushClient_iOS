/*
 * Copyright (c) 2022 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>

@interface ImageResource

@end

@interface DashImageCell : UICollectionViewCell

@property IBOutlet UILabel *label;
@property IBOutlet UIImageView *imageView;

/* locked resources (show/hide locked image) */
-(void)showLock;
-(void)hideLock;

@end
