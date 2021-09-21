/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <WebKit/WebKit.h>

@interface DashCustomItemView : UIView <WKURLSchemeHandler, WKNavigationDelegate>

@property (strong, nonatomic) WKWebView *webView;
@property UIActivityIndicatorView *progressBar;

-(void)showProgressBar;
-(void)hideProgressBar;

@end
