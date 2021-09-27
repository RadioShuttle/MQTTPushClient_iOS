/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCircleBackroundView.h"
#import "DashUtils.h"

@implementation DashCircleBackroundView

- (instancetype)init {
	if (self = [super init]) {
		[self setBackgroundColor:[UIColor clearColor]];
		//TODO: dark mode
		self.fillColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
	}
	return self;
}
- (void)drawRect:(CGRect)rect {
	CGRect r2;
	float a = MIN(rect.size.height, rect.size.width);
	r2.origin.x = rect.origin.x + 2.0f;
	if (rect.size.width > a) {
		r2.origin.x += (rect.size.width - a) / 2.0f;
	}
	r2.origin.y = rect.origin.y + 2.0f;
	if (rect.size.height > a) {
		r2.origin.y += (rect.size.height - a) / 2.0f;
	}
	
	r2.size.height = a - 4.0f;
	r2.size.width = a - 4.0f;
	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextAddEllipseInRect(ctx, r2);
	CGContextSetFillColorWithColor(ctx, [self.fillColor CGColor]);
	CGContextDrawPath(ctx, kCGPathFill);
}

@end
