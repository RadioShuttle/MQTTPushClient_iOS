/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <WebKit/WebKit.h>
#import "DashItemView.h"
#import "DashCustomItem.h"
#import "DashPublishController.h"

@class DashWebViewHandler;
@interface DashCustomItemView : DashItemView

@property (strong, nonatomic) WKWebView *webView;
/* indicates if webeview was already loaded (should be updated before calling onBind) */
@property BOOL loaded;
/* indicates if webview.load was called, and document has been loaded */
@property BOOL contentLoaded;

@property DashCustomItem *item;
/* to keep track of last passed historical message */
@property DashMessage *lastHistoricalMsg;
/* last passed historical data by on bind function */
@property NSArray<DashMessage *> *histData;
@property DashWebViewHandler *handler;
@property Account *account;

@property BOOL detached;
@property NSNumberFormatter *numberFormatter;

@end

@interface DashWebViewHandler : NSObject <WKURLSchemeHandler, WKNavigationDelegate, WKScriptMessageHandler>

-(instancetype)initWithView:(DashCustomItemView *)view;
- (void)onDashItemPropertyChanged:(NSNotification *)notif;
@property (weak) DashCustomItemView* dashView;
@property (weak) NSURL* userDataDir;
@end

