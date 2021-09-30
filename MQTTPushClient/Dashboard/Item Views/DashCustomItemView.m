/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCustomItemView.h"
#import "DashConsts.h"

@implementation DashCustomItemView

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self initWebView];		
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initWebView];
    }
    return self;
}

-(void) initWebView {
    WKWebViewConfiguration *c = [[WKWebViewConfiguration alloc] init];
	if (@available(iOS 11, *)) {
		[c setURLSchemeHandler:self forURLScheme:@"pushapp"];
	}
	
    _webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:c];
    _webView.navigationDelegate = self;
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_webView];
    
    [_webView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0].active = YES;
    [_webView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0].active = YES;
    [_webView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
    [_webView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
}

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask  API_AVAILABLE(ios(11.0)){
    NSLog(@"webview resource request: %@", urlSchemeTask.request.URL);
    
    UIImage *img = [UIImage imageNamed:@"baseline_filter_list_black_24pt"];
    NSData *d = UIImageJPEGRepresentation(img, 0.7);
    NSURLResponse *urlResponse = [[NSURLResponse alloc] initWithURL:urlSchemeTask.request.URL MIMEType:@"image/jpeg" expectedContentLength:-1 textEncodingName:nil];
    
    [urlSchemeTask didReceiveResponse:urlResponse];
    [urlSchemeTask didReceiveData:d];
    [urlSchemeTask didFinish];
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask  API_AVAILABLE(ios(11.0)){
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self hideProgressBar];
}

- (void)showProgressBar {
    if (!self.progressBar) {
        self.progressBar = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
        self.progressBar.color = [UIColor blackColor];
        self.progressBar.translatesAutoresizingMaskIntoConstraints = NO;
        [self.progressBar startAnimating];
        self.progressBar.layer.zPosition = 100.0f;
        [self addSubview:self.progressBar];
        
        [self.progressBar.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0.0].active = YES;
        [self.progressBar.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0.0].active = YES;
    }
}

- (void)hideProgressBar {
    if (self.progressBar) {
        [self.progressBar stopAnimating];
        [self.progressBar removeFromSuperview];
        self.progressBar = nil;
    }
}

-(void)onBind:(DashItem *)item context:(Dashboard *)context {
	Boolean load = NO;

	if (!self.dashCustomItem) { // first call?
		//TODO: set scripts here
		[self.webView.configuration.userContentController addScriptMessageHandler:self name:@"error"];
		[self.webView.configuration.userContentController addScriptMessageHandler:self name:@"log"];
		NSLog(@"Custom Item View (including webview): created");
		load = YES;
	} else if (item != self.dashCustomItem) {
		/* view has not been reused for a diffrent custom item */
	} else {
		/* view has been reused */
		[self.webView.configuration.userContentController removeAllUserScripts];
		load = YES;
	}
	self.dashCustomItem = (DashCustomItem *) item;
	if (load) {
		[self showProgressBar];
		
		/* background color */
		int64_t color;
		if (item.background == DASH_COLOR_OS_DEFAULT) {
			color = DASH_DEFAULT_CELL_COLOR; //TODO: dark mode use color from asset
		} else {
			color = item.background;
		}
		self.webView.opaque = NO;
		[self setBackgroundColor:UIColorFromRGB(color)];
		[self.webView.scrollView setBackgroundColor:UIColorFromRGB(color)];
		
		/* add error function */
		WKUserScript *errHandlerSkript = [[WKUserScript alloc] initWithSource:[[NSString alloc] initWithData:[[NSDataAsset alloc] initWithName:@"error_handler"].data encoding:NSUTF8StringEncoding] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
		[self.webView.configuration.userContentController addUserScript:errHandlerSkript];
		
		/* add log function */
		WKUserScript *logSkript = [[WKUserScript alloc] initWithSource:@"function log(t) {window.webkit.messageHandlers.log.postMessage(t);}" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
		[self.webView.configuration.userContentController addUserScript:logSkript];
		
		/* call Dash-javascript init function: */
		WKUserScript *initSkript = [[WKUserScript alloc] initWithSource:@"onMqttInit(); log('Clock app initialized!');" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
		[self.webView.configuration.userContentController addUserScript:initSkript];
		
		[self.webView loadHTMLString:self.dashCustomItem.html baseURL:[NSURL URLWithString:@"pushapp://pushclient/"]];

		/* when passing messages to custom view use: [webView evaluateJavaScript:@"onMqttMessage(...); " completionHandler:^(NSString *result, NSError *error) {}] */
		/* When using [webView evaluateJavaScript ...] the document must have been fully loaded! This can be checked with via WKNavigationDelegate.didFinishNavigation callback */
		self.webView.navigationDelegate = self;
	}
}

/* script message handler */
-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
	NSLog(@"Received message: %@", message.body);
}


@end
