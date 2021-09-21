/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCustomItemView.h"

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
    [c setURLSchemeHandler:self forURLScheme:@"pushapp"];
    
    _webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:c];
    _webView.navigationDelegate = self;
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_webView];
    
    [_webView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0].active = YES;
    [_webView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0].active = YES;
    [_webView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = YES;
    [_webView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0].active = YES;
}

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    NSLog(@"webview resource request: %@", urlSchemeTask.request.URL);
    
    UIImage *img = [UIImage imageNamed:@"baseline_filter_list_black_24pt"];
    NSData *d = UIImageJPEGRepresentation(img, 0.7);
    NSURLResponse *urlResponse = [[NSURLResponse alloc] initWithURL:urlSchemeTask.request.URL MIMEType:@"image/jpeg" expectedContentLength:-1 textEncodingName:nil];
    
    [urlSchemeTask didReceiveResponse:urlResponse];
    [urlSchemeTask didReceiveData:d];
    [urlSchemeTask didFinish];
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {

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

@end
