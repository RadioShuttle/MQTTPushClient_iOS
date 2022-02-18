/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCustomItemViewCell.h"
#import "Utils.h"
#import "DashConsts.h"

@implementation DashCustomItemViewCell

-(void)onBind:(DashItem *)item context:(Dashboard *)context selected:(BOOL)selected {
	self.dashboard = context;
	
	if (context.cachedCustomViewsVersion != context.localVersion) {
		/* clear cache - dashbaord has been updated */
		[context.cachedCustomViews removeAllObjects];
		context.cachedCustomViewsVersion = context.localVersion;
	}
	
	/* webview (DashCustomItemView) replacement - use cached webview if exists */
	
	DashCustomItemView *cachedView = context.cachedCustomViews[@(item.id_)];
	DashCustomItemView *e;
	if (cachedView != nil && cachedView == self.webviewContainer) {
		/* no action needed */
	} else if (cachedView != nil) {
		/* use cached view */
		[self replaceDashCustomView:cachedView];
	} else {
		/* there is no cached object */
		BOOL createNew = NO;
		if (self.webviewContainer == nil) {
			createNew = YES;
		} else {
			/* check if self.webviewcontainer is used by other item */
			for(NSNumber *key in context.cachedCustomViews) {
				e = context.cachedCustomViews[key];
				if (e == self.webviewContainer) {
					if (!self.webviewContainer.detached) {
						[self.webviewContainer removeFromSuperview];
						self.webviewContainer.detached = YES;
						[self.customItemLabel removeFromSuperview];
					}
					/* webview of this cell may not be used here */
					self.webviewContainer = nil;
					createNew = YES;
					break;
				}
			}
		}
		if (createNew) {
			DashCustomItemView *newCustomView = [[DashCustomItemView alloc] init];
			[self setConstraints:newCustomView];
		}
	}
	// NSLog(@"Item: %@ %p", item.label, self.webviewContainer);
	self.webviewContainer.container = self;
	[self.dashboard.cachedCustomViews setObject:self.webviewContainer forKey:@(item.id_)];
	
	/* end webview replacement */
	
	if (self.webviewContainer.userInteractionEnabled) {
		self.webviewContainer.userInteractionEnabled = NO;
	};
	[self.webviewContainer onBind:item context:context container:self];

	[super onBind:item context:context label:self.customItemLabel selected:selected];

}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
	return [super initWithCoder:aDecoder];
}

-(instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	DashCustomItemView *cv = [[DashCustomItemView alloc] init];
	[self setConstraints:cv];
	
	return self;
}

-(void)setConstraints:(DashCustomItemView *)cv {
	cv.translatesAutoresizingMaskIntoConstraints = NO;
	[self.contentView addSubview:cv];
	
	UILabel *label = [[UILabel alloc] init];
	[label setFont:[UIFont systemFontOfSize:DASH_LABEL_FONT_SIZE]];
	label.translatesAutoresizingMaskIntoConstraints = NO;
	[self.contentView addSubview:label];
	
	label.textAlignment = NSTextAlignmentCenter;
	label.lineBreakMode = NSLineBreakByTruncatingTail;
	
	[label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0].active = YES;
	[label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
	[label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
	
	[cv.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0].active = YES;
	[cv.bottomAnchor constraintEqualToAnchor:label.topAnchor constant:0.0].active = YES;
	[cv.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
	[cv.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
	
	self.webviewContainer = cv;
	self.customItemLabel = label;
}
	
- (void)onUpdate:(DashCustomItem *)item what:(NSString *)what {
	if ([what isEqualToString:@"error"]) {
		BOOL error1 = ![Utils isEmpty:item.error1];
		BOOL error2 = ![Utils isEmpty:item.error2];
		[self showErrorInfo:error1 error2:error2];
	}
}

-(DashCustomItemView *)replaceDashCustomView:(DashCustomItemView *)cachedView {
	if (!cachedView.detached) {
		DashCustomItemViewCell * cachedViewParent = (DashCustomItemViewCell *) [[cachedView superview] superview];
		[cachedViewParent.webviewContainer removeFromSuperview];
		[cachedViewParent.customItemLabel removeFromSuperview];
		cachedViewParent.webviewContainer = nil;
		cachedView.detached = YES;
	}

	if (!self.webviewContainer.detached) {
		[self.webviewContainer removeFromSuperview];
		[self.customItemLabel removeFromSuperview];
		self.webviewContainer.detached = YES;
	}

	DashCustomItemView *old = self.webviewContainer;
	
	self.webviewContainer = cachedView;
	self.webviewContainer.detached = NO;
	
	[self setConstraints:self.webviewContainer];
	
	return old;
}

@end
