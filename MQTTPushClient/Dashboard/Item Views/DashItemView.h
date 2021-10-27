/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashItem.h"
#import "Dashboard.h"

@protocol DashPublishController
-(void) performSend:(NSData *)data queue:(BOOL)queue;
-(void) performSend:(NSString *)topic data:(NSData *)data retain:(BOOL)retain queue:(BOOL)queue;
-(DashItem *) getItem;
@end

@interface DashItemView : UIView

@property UIImageView *backgroundImageView;
/* indicates if this view is used in detail view */
@property BOOL detailView;

/* true, if publish topic or script_p is set */
@property BOOL publishEnabled;

@property id<DashPublishController> controller;

-(void)onBind:(DashItem *)item context:(Dashboard *)context;
/* call this to add an empty ImageView to this view. this should be called before adding any other elements (beacuase of layering) */
-(void)addBackgroundImageView;

/* detail view constructor */
- (instancetype)initDetailViewWithFrame:(CGRect)frame;


@end
