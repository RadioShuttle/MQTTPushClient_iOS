/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCustomItemViewCell.h"

@implementation DashCustomItemViewCell

// call onMqttInit() when document has been loaded
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.webviewContainer hideProgressBar];
    /*
    [webView evaluateJavaScript:@"onMqttInit(); log('hello world!');" completionHandler:^(NSString *result, NSError *error)
    {
        NSLog(@"Error %@",error);
        NSLog(@"Result %@",result);
    }];
     */
}

-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"Received message: %@", message.body);
}

@end
