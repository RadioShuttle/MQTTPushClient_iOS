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
		self.account = context.account;
		self.handler.userDataDir = context.account.cacheURL;
		NSLog(@"Custom Item View (including webview): created");  //TODO: remove later
		load = YES;
	} else if (item == self.dashCustomItem) {
		/* view has not been reused for a diffrent custom item */
		NSLog(@"DashCustomItemView has not beeing reused."); //TODO: remove later
		if (self.contentLoaded) {
			//TODO: call js onMqttMessage
		}
		
	} else {
		NSLog(@"DashCustomItemView used for diffrent item"); //TODO: remove later
		//TODO: test if recycling works as intendent
		/* view has been reused */
		[self.webView.configuration.userContentController removeAllUserScripts];
		self.contentLoaded = NO;
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
		
		/* add Dash library functions */
		NSURL *dashLibURL = [[NSBundle mainBundle] URLForResource:@"javascript_webview" withExtension:@"js"];
		NSString *dashLibStr = [NSString stringWithContentsOfURL:dashLibURL encoding:NSUTF8StringEncoding error:NULL];

		WKUserScript *dashLibSkript = [[WKUserScript alloc] initWithSource:dashLibStr injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
		[self.webView.configuration.userContentController addUserScript:dashLibSkript];

		NSURL *colorsScriptURL = [[NSBundle mainBundle] URLForResource:@"javascript_color" withExtension:@"js"];
		NSString *colorScriptStr = [NSString stringWithContentsOfURL:colorsScriptURL encoding:NSUTF8StringEncoding error:NULL];

		WKUserScript *colorsSkript = [[WKUserScript alloc] initWithSource:colorScriptStr injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
		[self.webView.configuration.userContentController addUserScript:colorsSkript];

		/* build objects with item and account data */
		//TODO: consider moving code block to method after test/impl.
		NSString *enc;
		NSMutableString *itemDataCode = [NSMutableString new];
		[itemDataCode appendString:@"MQTT.view = new Object();"];
		//TODO: add view properties
		
		[itemDataCode appendString:@"MQTT.acc = new Object();"];
		[itemDataCode appendString:@"MQTT.acc.user = decodeURIComponent('"];
		enc = [self.account.mqttUser stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
		[itemDataCode appendString:enc];
		[itemDataCode appendString:@"');"];
		[itemDataCode appendString:@"MQTT.acc.mqttServer = decodeURIComponent('"];
		enc = [self.account.mqttHost stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
		[itemDataCode appendString:enc];
		[itemDataCode appendString:@"');"];
		[itemDataCode appendString:@"MQTT.acc.pushServer = decodeURIComponent('"];
		//TODO: context.account.pushServerID != pushserver address
		enc = [self.account.pushServerID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
		[itemDataCode appendString:enc];
		[itemDataCode appendString:@"');"];
		[itemDataCode appendString:@"MQTT.view.isDialog = function() { return "];
		[itemDataCode appendString:(self.userInput ? @"true" : @"false")];
		[itemDataCode appendString:@";}; "];

		WKUserScript *itemDataSkript = [[WKUserScript alloc] initWithSource:itemDataCode injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
		[self.webView.configuration.userContentController addUserScript:itemDataSkript];

		[self.webView loadHTMLString:self.dashCustomItem.html baseURL:[NSURL URLWithString:@"pushapp://pushclient/"]];
	}
}

-(void)injectInitCode {
	NSMutableString *code = [NSMutableString new];
	[code appendString:@"if (typeof window['onMqttInit'] === 'function') onMqttInit("];
	[code appendString:@"MQTT.acc"];
	[code appendString:@","];
	[code appendString:@"MQTT.view"];
	[code appendString:@"); "];
	
	//TODO: append onMqttMessage call, if message data exists

	[self.webView evaluateJavaScript:code completionHandler:nil];
}

-(void)dealloc {
	[self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"error"];
	[self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"log"];
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
	self.dashView.contentLoaded = YES;
	[self.dashView injectInitCode];
}

/* script message handler */
-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
	NSLog(@"Received message: %@", message.body);
}

-(void)dealloc {
	// NSLog(@"dealloc");
}

@end

