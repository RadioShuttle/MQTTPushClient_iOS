/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCustomItemView.h"
#import "DashConsts.h"
#import "DashUtils.h"
#import "NSString+HELUtils.h"


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
	self.handler = [[DashWebViewHandler alloc] initWithView:self];
	[c setURLSchemeHandler:self.handler forURLScheme:@"pushapp"];

    self.webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:c];
	self.webView.navigationDelegate = self.handler;
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_webView];
    
    [self.webView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0].active = YES;
    [self.webView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0].active = YES;
    [self.webView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
    [self.webView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
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
		[self.webView.configuration.userContentController addScriptMessageHandler:self.handler name:@"error"];
		[self.webView.configuration.userContentController addScriptMessageHandler:self.handler name:@"log"];
		self.handler.userDataDir = context.account.cacheURL;
		NSLog(@"Custom Item View (including webview): created");
		load = YES;
	} else if (item == self.dashCustomItem) {
		/* view has not been reused for a diffrent custom item */
		// NSLog(@"DashCustomItemView has not beeing reused.");
	} else {
		NSLog(@"DashCustomItemView used for diffrent item");
		/* view has been reused */
		//TODO: change scripts?
		/*
		[self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"log"];
		[self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"error"];
		[self.webView.configuration.userContentController removeAllUserScripts];
		 */
		load = YES;
	}
	self.dashCustomItem = (DashCustomItem *) item;
	if (load) {
		[self showProgressBar];
		
		/* background color */
		int64_t color = item.background;
		if (color == DASH_COLOR_OS_DEFAULT) {
			color = DASH_DEFAULT_CELL_COLOR; //TODO: dark mode use color from asset
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
	}
}

@end

@implementation DashWebViewHandler

-(instancetype)initWithView:(DashCustomItemView *)view {
	self = [super init];
	if (self) {
		self.dashView = view;
	}
	return self;
}

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
	NSLog(@"webview resource request: %@", [urlSchemeTask.request.URL path]);
	
	NSString *path = [urlSchemeTask.request.URL path];
	if ([path hasPrefix:@"/"]) {
		path = [path substringFromIndex:1];
	}

	NSData *data;
	NSURLResponse *urlResponse;
	NSString *uri = [DashUtils getResourceURIFromResourceName:path userDataDir:self.userDataDir];
	if (uri) {
		NSString *resourceName = [DashUtils getURIPath:uri];

		if ([DashUtils isUserResource:uri]) {
			NSString *internalFilename = [NSString stringWithFormat:@"%@.%@", [resourceName enquoteHelios], DASH512_PNG];
			NSURL *localDir = [DashUtils getUserFilesDir:self.userDataDir];
			NSURL *fileURL = [DashUtils appendStringToURL:localDir str:internalFilename];
			if ([DashUtils fileExists:fileURL]) {
				urlResponse = [[NSURLResponse alloc] initWithURL:urlSchemeTask.request.URL MIMEType:@"image/png" expectedContentLength:-1 textEncodingName:nil];
				data = [[NSData alloc] initWithContentsOfURL:fileURL];
			}
		} else if ([DashUtils isInternalResource:uri]) {
			NSURL *svgImageURL = [[NSBundle mainBundle] URLForResource:resourceName withExtension:@"svg"];
			if ([DashUtils fileExists:svgImageURL]) {
				urlResponse = [[NSURLResponse alloc] initWithURL:urlSchemeTask.request.URL MIMEType:@"image/svg+xml" expectedContentLength:-1 textEncodingName:nil];
				data = [[NSData alloc] initWithContentsOfURL:svgImageURL];
			}
		}
	}
	if (!urlResponse) {
		/* resource not found */
		urlResponse = [[NSHTTPURLResponse alloc] initWithURL:urlSchemeTask.request.URL statusCode:404 HTTPVersion:@"HTTP/1.1" headerFields:nil];
	}
	
	[urlSchemeTask didReceiveResponse:urlResponse];
	[urlSchemeTask didReceiveData:data];
	[urlSchemeTask didFinish];
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	[self.dashView hideProgressBar];
}

/* script message handler */
-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
	NSLog(@"Received message: %@", message.body);
}

-(void)dealloc {
	// NSLog(@"dealloc");
}

@end

