/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCustomItemView.h"
#import "DashConsts.h"
#import "DashUtils.h"
#import "Utils.h"
#import "NSString+HELUtils.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "DashCustomItemViewCell.h"
#import "DashDetailViewController.h"

@implementation DashCustomItemView

static int32_t handlerID = 0;

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

- (instancetype)initDetailViewWithFrame:(CGRect)frame {
	self = [super initDetailViewWithFrame:frame];
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
	[super onBind:item context:context];
	
	/* background color */
	int64_t color = item.background;
	if (color == DASH_COLOR_OS_DEFAULT) {
		color = DASH_DEFAULT_CELL_COLOR; //TODO: dark mode use color from asset
	}
	self.webView.opaque = NO;
	[self.webView.scrollView setBackgroundColor:UIColorFromRGB(color)];
	
	BOOL load = NO;
	
	if (!self.item) { // first call?
		[self.webView.configuration.userContentController addScriptMessageHandler:self.handler name:@"error"];
		[self.webView.configuration.userContentController addScriptMessageHandler:self.handler name:@"log"];
		[self.webView.configuration.userContentController addScriptMessageHandler:self.handler name:@"publish"];
		[self.webView.configuration.userContentController addScriptMessageHandler:self.handler name:@"setBackgroundColor"];
		self.account = context.account;
		self.handler.userDataDir = context.account.cacheURL;
		load = YES;

	} else if (item == self.item) {
		/* message update */
	} else {
		/* view has been reused */
		[self.webView.configuration.userContentController removeAllUserScripts];
		self.contentLoaded = NO;
		self.lastHistoricalMsg = nil;
		self.histData = nil;
		load = YES;
	}
	
	self.item = (DashCustomItem *) item;
	if (item.history) {
		self.histData = [context.historicalData objectForKey:self.item.topic_s];
	}
	
	if (load) {
		[self showProgressBar];
		
		NSURL *colorsScriptURL = [[NSBundle mainBundle] URLForResource:@"javascript_color" withExtension:@"js"];
		NSString *colorScriptStr = [NSString stringWithContentsOfURL:colorsScriptURL encoding:NSUTF8StringEncoding error:NULL];
		
		WKUserScript *colorsSkript = [[WKUserScript alloc] initWithSource:colorScriptStr injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
		[self.webView.configuration.userContentController addUserScript:colorsSkript];
		
		/* add Dash library functions */
		NSURL *dashLibURL = [[NSBundle mainBundle] URLForResource:@"javascript_webview" withExtension:@"js"];
		NSString *dashLibStr = [NSString stringWithContentsOfURL:dashLibURL encoding:NSUTF8StringEncoding error:NULL];
		
		WKUserScript *dashLibSkript = [[WKUserScript alloc] initWithSource:dashLibStr injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
		[self.webView.configuration.userContentController addUserScript:dashLibSkript];
		
		/* add a unique handler ID */
		self.item.handlerID = ++handlerID;
		WKUserScript *handlerIDSkript = [[WKUserScript alloc] initWithSource:[NSString stringWithFormat:@"MQTT._handlerID = %d;", handlerID] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
		[self.webView.configuration.userContentController addUserScript:handlerIDSkript];
		
		NSString *itemDataCode = [self buildItemDataCode];
		WKUserScript *itemDataSkript = [[WKUserScript alloc] initWithSource:itemDataCode injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
		[self.webView.configuration.userContentController addUserScript:itemDataSkript];
		
		[self.webView loadHTMLString:self.item.html baseURL:[NSURL URLWithString:@"pushapp://pushclient/"]];
	} else {
		if (self.contentLoaded) {
			[self.webView evaluateJavaScript:[self buildOnMqttMessageCode] completionHandler:nil];
		}
	}
}

-(void)injectInitCode {
	NSMutableString *code = [NSMutableString new];
	[code appendString:@"if (typeof window['onMqttInit'] === 'function') onMqttInit("];
	[code appendString:@"MQTT.acc"];
	[code appendString:@","];
	[code appendString:@"MQTT.view"];
	[code appendString:@"); "];
	
	if (self.item.message) {
		[code appendString:[self buildOnMqttMessageCode]];
	}
	
	[self.webView evaluateJavaScript:code completionHandler:nil];
}

-(NSString *)buildItemDataCode {
	/* build objects with item and account data */
	NSString *enc;
	NSMutableString *itemDataCode = [NSMutableString new];
	
	/* parameters */
	for(int i = 0; i < self.item.parameter.count; i++) {
		[itemDataCode appendFormat:@"MQTT.view._parameters[%d", i];
		[itemDataCode appendString:@"] = decodeURIComponent('"];
		enc = [self urlEnc:self.item.parameter[i]];
		[itemDataCode appendString:enc];
		[itemDataCode appendString:@"'); "];
	}
	
	/* account data */
	[itemDataCode appendString:@"MQTT.acc = new Object();"];
	[itemDataCode appendString:@"MQTT.acc.user = decodeURIComponent('"];
	enc = [self urlEnc:self.account.mqttUser];
	[itemDataCode appendString:enc];
	[itemDataCode appendString:@"');"];
	[itemDataCode appendString:@"MQTT.acc.mqttServer = decodeURIComponent('"];
	enc = [self urlEnc:self.account.mqttHost];
	[itemDataCode appendString:enc];
	[itemDataCode appendString:@"');"];
	[itemDataCode appendString:@"MQTT.acc.pushServer = decodeURIComponent('"];
	enc = [self urlEnc:self.account.pushServerID];
	[itemDataCode appendString:enc];
	[itemDataCode appendString:@"');"];
	
	/* detail view ? */
	[itemDataCode appendString:@"MQTT.view.isDialog = function() { return "];
	[itemDataCode appendString:(self.detailView ? @"true" : @"false")];
	[itemDataCode appendString:@";}; "];
	
	/* subscribed topic */
	[itemDataCode appendString:@"MQTT.view._subscribedTopic = decodeURIComponent('"];
	enc = [self urlEnc:self.item.topic_s];
	[itemDataCode appendString:enc];
	[itemDataCode appendString:@"');"];
	
	return itemDataCode;
}

-(NSString *)buildOnMqttMessageCode {
	NSMutableString *code = [NSMutableString new];
	
	//TODO: recycle error self.histData
	if (self.histData) {
		for(int i = 0; i < self.histData.count; i++) {
			if (!self.lastHistoricalMsg || [self.histData[i] isNewerThan:self.lastHistoricalMsg]) {
				[self addHistMessageToCode:code message:self.histData[i]];
			}
		}
		self.lastHistoricalMsg = self.histData.lastObject;
	}
	
	if (self.item.message) {
		[code appendString:@"if (typeof window['onMqttMessage'] === 'function') _onMqttMessage("];
		[self appendMessageFuncArgs:code message:self.item.message];
		[code appendString:@");"];
	}
	return code;
}

-(NSString *)buildOnRequestFinishedCode {
	return @"MQTT._requestRunning = false;";
}

-(void)addHistMessageToCode:(NSMutableString *)code message:(DashMessage *)message {
	if (message) {
		[code appendString:@"_addHistDataMsg("];
		[self appendMessageFuncArgs:code message:message];
		[code appendString:@");"];
	}
}
/* builds "receivedDateMillis, topic, payloadStr, payloadHEX" */
-(void)appendMessageFuncArgs:(NSMutableString *)code message:(DashMessage *)message {
	NSString *enc;
	
	/* message date epoche 1970 ms */
	NSTimeInterval when = [message.timestamp timeIntervalSince1970] * 1000.0L;
	[code appendFormat:@"%lld", (uint64_t) when];
	[code appendString:@", "];
	
	/* topic */
	[code appendString:@"decodeURIComponent('"];
	enc = [self urlEnc:message.topic];
	[code appendString:enc];
	[code appendString:@"'),"];
	
	/* message str */
	[code appendString:@"decodeURIComponent('"];
	enc = [message contentToStr];
	enc = [self urlEnc:enc];
	[code appendString:enc];
	[code appendString:@"'),"];
	
	/* raw */
	[code appendString:@"'"];
	enc = [message contentToHex];
	[code appendString:enc];
	[code appendString:@"'"];
	
}

-(NSString *)urlEnc:(NSString *)v {
	return [(v ? v : @"") stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

-(void)dealloc {
	[self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"error"];
	[self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"log"];
	[self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"publish"];
	[self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"setBackgroundColor"];
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
	if ([message.name isEqualToString:@"error"]) {
		[self handleWebviewError:message.body];
	} else if ([message.name isEqualToString:@"log"]) {
		NSLog(@"%@", message.body);
	} else if ([message.name isEqualToString:@"setBackgroundColor"]) {
		if ([message.body isKindOfClass:[NSDictionary class]]) {
			uint32_t handlerID = [[((NSDictionary *) message.body) helNumberForKey:@"handlerID"] unsignedIntValue];
			if (self.dashView.item.handlerID == handlerID) {
				int64_t color =[[((NSDictionary *) message.body) helNumberForKey:@"color"] longLongValue];
				self.dashView.item.background = color;
				if (color == DASH_COLOR_OS_DEFAULT) {
					color = DASH_DEFAULT_CELL_COLOR; //TODO: dark mode use color from asset
				}
				/* update this views background color */
				[self.dashView setBackgroundColor:UIColorFromRGB(color)];
				[self.dashView.webView.scrollView setBackgroundColor:UIColorFromRGB(color)];
				if ([[[self.dashView superview] superview] conformsToProtocol:@protocol(DashCustomViewContainer)]) {
					id<DashCustomViewContainer> p = (id<DashCustomViewContainer>) [[self.dashView superview] superview];
					[p onUpdate:self.dashView.item what:@"background"];
					/* notify observer in case another view needs this info */
					//TODO: check
					// [self notifyObserver:@"background"];
				}
			}
		}
	} else if ([message.name isEqualToString:@"publish"]) {
		if ([message.body isKindOfClass:[NSDictionary class]]) {
			NSString *topic = [message.body helStringForKey:@"topic"];
			BOOL retain = [[message.body helNumberForKey:@"retain"] boolValue];

			NSData *payload;
			if ([message.body objectForKey:@"msg_str"]) {
				NSString *messageStr = [message.body helStringForKey:@"msg_str"];
				payload = [messageStr dataUsingEncoding:NSUTF8StringEncoding];
				
			} else if ([message.body objectForKey:@"msg"]) {
				/* hex */
				NSString *messageHex = [message.body helStringForKey:@"msg"];
				payload = [messageHex dataFromHex];
			}
			
			if (payload == nil) {
				payload = [[NSData alloc] init];
			}
			
			[self.dashView.controller performSend:topic data:payload retain:retain queue:NO];
						
			//TODO: remove code lines later:
			/*
			NSString *code = [self.dashView buildOnRequestFinishedCode];
			[self.dashView.webView evaluateJavaScript:code completionHandler:nil];
			*/
		}
	}
}

-(void)handleWebviewError:(NSObject *)errorDict {
	/* build error object */
	if ([errorDict isKindOfClass:[NSDictionary class]]) {
		uint32_t handlerID = [[((NSDictionary *) errorDict) helNumberForKey:@"handlerID"] unsignedIntValue];
		NSString *message = [((NSDictionary *) errorDict) helStringForKey:@"message"];
		NSNumber *line = [((NSDictionary *) errorDict) helNumberForKey:@"line"];
		NSString * errorMsg = [NSString stringWithFormat:@"%@, line: %d", message, [line intValue]];
		/* error already reported ?*/
		if (handlerID == self.dashView.item.handlerID /* && ![errorMsg isEqualToString:self.dashView.item.error1] */) {
			self.dashView.item.error1 = errorMsg;
			// [self.dashView.parentContainer onUpdate:self.dashView.item what:@"error"]; //TODO
			if ([[[self.dashView superview] superview] conformsToProtocol:@protocol(DashCustomViewContainer)]) {
				id<DashCustomViewContainer> p = (id<DashCustomViewContainer>) [[self.dashView superview] superview];
				[p onUpdate:self.dashView.item what:@"error"];
				/* notify observer in case another view needs this info */
				//TODO: check
				// [self notifyObserver:@"background"];
			}
		}
	}
}

-(void)notifyObserver:(NSString *)updateProperty {
	/* notify observer */
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	// [userInfo setObject:[NSNumber numberWithUnsignedLongLong:self.dashView.dashVersion] forKey:@"version"];
	[userInfo setObject:[NSNumber numberWithUnsignedInt:self.dashView.item.id_] forKey:@"item_id"];
	[userInfo setObject:[NSNumber numberWithBool:self.dashView.detailView] forKey:@"detail_view"];
	[userInfo setObject:updateProperty forKey:@"updated_property"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DashItemPropertyUpdate" object:nil userInfo:userInfo];
	
}

@end

