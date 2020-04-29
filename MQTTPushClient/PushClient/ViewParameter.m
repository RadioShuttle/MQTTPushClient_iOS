/*
 * Copyright (c) 2020 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <JavaScriptCore/JavaScriptCore.h>
#import "ViewParameter.h"

@protocol JSViewExports <JSExport>
- (void)setTextColor:(int64_t)color;
- (void)setBackgroundColor:(int64_t)color;
- (int64_t)getTextColor;
- (int64_t)getBackgroundColor;
@end

@interface ViewParameter () <JSViewExports>
@end

@implementation ViewParameter

-(instancetype)init {
	self = [super init];
	if (self) {
		_currentTextColor = DColorOSDefault;
		_currentBackgroundColor = DColorOSDefault;
	}
	return self;
}

- (void)setTextColor:(int64_t)color {
	self.currentTextColor = color;
}

- (void)setBackgroundColor:(int64_t)color {
	self.currentBackgroundColor = color;
}

- (int64_t)getTextColor {
	return self.currentTextColor;
}

- (int64_t)getBackgroundColor {
	return self.currentBackgroundColor;
}

- (UIColor *)uiTextColor {
	return [self uiColorFrom:self.currentTextColor];
}

- (UIColor *)uiBackgroundColor {
	return [self uiColorFrom:self.currentBackgroundColor];
}

- (UIColor *)uiColorFrom:(int64_t)color {
	if (color == DColorOSDefault || color == DColorClear) {
		return nil;
	}
	CGFloat alpha = ((color >> 24) & 0xFF)/255.0;
	CGFloat red =   ((color >> 16) & 0xFF)/255.0;
	CGFloat green = ((color >> 8)  & 0xFF)/255.0;
	CGFloat blue =  ((color >> 0)  & 0xFF)/255.0;
	return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}
@end
