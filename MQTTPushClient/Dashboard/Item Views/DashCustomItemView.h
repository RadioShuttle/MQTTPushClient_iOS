/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <WebKit/WebKit.h>
#import "DashItemView.h"
#import "DashCustomItem.h"

@class DashWebViewHandler;
@interface DashCustomItemView : DashItemView

@property (strong, nonatomic) WKWebView *webView;
@property UIActivityIndicatorView *progressBar;
/* indicates if webeview was already loaded (should be updated before calling onBind) */
@property BOOL loaded;
@property DashCustomItem *dashCustomItem;
@property DashWebViewHandler *handler;

-(void)showProgressBar;
-(void)hideProgressBar;

@end

@interface DashWebViewHandler : NSObject <WKURLSchemeHandler, WKNavigationDelegate, WKScriptMessageHandler>

-(instancetype)initWithView:(DashCustomItemView *)view;

@property (weak) DashCustomItemView* dashView;
@property (weak) NSURL* userDataDir;
@end

