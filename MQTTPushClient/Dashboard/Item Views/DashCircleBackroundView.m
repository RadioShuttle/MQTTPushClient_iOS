/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCircleBackroundView.h"
#import "DashUtils.h"

@implementation DashCircleBackroundView

- (instancetype)init {
	return [self initWithColor:[UIColor whiteColor]];
}

- (instancetype)initWithColor:(UIColor*) color {
	if (self = [super init]) {
		[self setBackgroundColor:[UIColor clearColor]];
		self.fillColor = color;
		self.padding = 2;
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	CGRect r2;
	float a = MIN(rect.size.height, rect.size.width);
	r2.origin.x = rect.origin.x + self.padding;
	if (rect.size.width > a) {
		r2.origin.x += (rect.size.width - a) / self.padding;
	}
	r2.origin.y = rect.origin.y + self.padding;
	if (rect.size.height > a) {
		r2.origin.y += (rect.size.height - a) / self.padding;
	}
	
	r2.size.height = a - self.padding * 2;
	r2.size.width = a - self.padding * 2;
	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextAddEllipseInRect(ctx, r2);
	CGContextSetFillColorWithColor(ctx, [self.fillColor CGColor]);
	CGContextDrawPath(ctx, kCGPathFill);
}

@end
