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
/* indicates if webview.load was called, and document has been loaded */
@property BOOL contentLoaded;
/* true when used in detail dialog view */
@property BOOL userInput;
@property DashCustomItem *dashCustomItem;
@property DashWebViewHandler *handler;
@property Account *account;

-(void)showProgressBar;
-(void)hideProgressBar;

@end

@interface DashWebViewHandler : NSObject <WKURLSchemeHandler, WKNavigationDelegate, WKScriptMessageHandler>

-(instancetype)initWithView:(DashCustomItemView *)view;

@property (weak) DashCustomItemView* dashView;
@property (weak) NSURL* userDataDir;
@end

