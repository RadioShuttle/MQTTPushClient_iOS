/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <WebKit/WebKit.h>
#import "DashItemView.h"
#import "DashCustomItem.h"

@interface DashCustomItemView : DashItemView <WKURLSchemeHandler, WKNavigationDelegate, WKScriptMessageHandler>

@property (strong, nonatomic) WKWebView *webView;
@property UIActivityIndicatorView *progressBar;
/* indicates if webeview was already loaded (should be updated before calling onBind) */
@property BOOL loaded;
@property DashCustomItem *dashCustomItem;

-(void)showProgressBar;
-(void)hideProgressBar;

@end
