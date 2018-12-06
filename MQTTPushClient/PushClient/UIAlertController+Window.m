//
//  UIAlertController+Window.m
//  FFM
//
//  Created by Eric Larson on 6/17/15.
//  Copyright (c) 2015 ForeFlight, LLC. All rights reserved.
//

/*
 Downloaded from https://github.com/agilityvision/FFGlobalAlertController,
 available under the MIT License.
 
 LICENSE
 
 Copyright (c) 2015 Eric Larson <eric@agilityvision.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "UIAlertController+Window.h"
#import <objc/runtime.h>

@interface UIAlertController (Private)

@property (nonatomic, strong, readonly) UIWindow *helAlertWindow;

@end

@implementation UIAlertController (Private)

@dynamic helAlertWindow;

- (void)setHelAlertWindow:(UIWindow *)alertWindow {
    objc_setAssociatedObject(self, @selector(helAlertWindow), alertWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIWindow *)helAlertWindow {
    return objc_getAssociatedObject(self, @selector(helAlertWindow));
}

@end

@implementation UIAlertController (Window)

- (void)helShow {
    [self helShow:YES];
}

- (void)helShow:(BOOL)animated {
    self.helAlertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.helAlertWindow.rootViewController = [[UIViewController alloc] init];
    self.helAlertWindow.windowLevel = UIWindowLevelAlert + 1;
    [self.helAlertWindow makeKeyAndVisible];
    [self.helAlertWindow.rootViewController presentViewController:self animated:animated completion:nil];
}

@end
