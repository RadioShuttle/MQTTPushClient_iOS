/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashItem.h"
#import "Dashboard.h"
#import "DashPublishController.h"

@interface DashItemView : UIView

@property UIImageView *backgroundImageView;
/* indicates if this view is used in detail view */
@property BOOL detailView;

/* true, if publish topic or script_p is set */
@property BOOL publishEnabled;

@property uint64_t dashVersion;
@property UIActivityIndicatorView *progressBar;

-(void)onBind:(DashItem *)item context:(Dashboard *)context;
/* call this to add an empty ImageView to this view. this should be called before adding any other elements (beacuase of layering) */
-(void)addBackgroundImageView;

/* detail view constructor */
- (instancetype)initDetailViewWithFrame:(CGRect)frame;

/* the publish id of the currently running request */
@property uint32_t currentPublishID;
/* if a publish command is already running a value might be queued until request finished */
@property NSData *queue;

@property (weak) id<DashPublishController> publishController;
@property DashItem *dashItem;

-(void) performSend:(NSData *)data queue:(BOOL)queue;
-(void) performSend:(NSString *)topic data:(NSData *)data retain:(BOOL)retain queue:(BOOL)queue item:(DashItem *)item;

- (void)showProgressBar;
- (void)hideProgressBar;
/* will be called when a publish request finishes. returns true, if requestID matches */
-(BOOL) onPublishRequestFinished:(uint32_t) requestID;

@end
