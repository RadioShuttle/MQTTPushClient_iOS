/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import WebKit;
#import "WebViewController.h"

static NSString *OpenExternal = @"openExternal=yes";

@interface WebViewController () <WKNavigationDelegate>

@property (strong, nonatomic) WKWebView *webView;

@end

@implementation WebViewController

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		_webView = [[WKWebView alloc] initWithFrame:CGRectZero];
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Add WKWebView to view hierarchy and add layout constraints:
	[self.view insertSubview:self.webView atIndex:0];
	_webView.navigationDelegate = self;
	self.webView.translatesAutoresizingMaskIntoConstraints = NO;
	NSDictionary *bindings = @{ @"webView" : self.webView };
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[webView]-|" options:0 metrics:nil views:bindings]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView]|" options:0 metrics:nil views:bindings]];
	[self.webView loadRequest:self.request];
	NSLog(@"frame: %f %f %f %f", self.webView.frame.origin.x, self.webView.frame.origin.y, self.webView.frame.size.width, self.webView.frame.size.height);
}


@end
