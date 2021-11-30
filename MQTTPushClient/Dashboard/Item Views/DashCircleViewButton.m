/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCircleViewButton.h"
#import "DashConsts.h"
#import "DashUtils.h"

@implementation DashCircleViewButton

- (instancetype)init
{
    self = [super init];
    if (self) {
		[self initDef];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initDef];
	}
	return self;
}

-(void)initDef {
	self.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.7]; //TODO: dark mode
	self.fillColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
	
	UIImage *highlightColorImg = [DashUtils imageWithColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.5f]];
	[self setBackgroundImage:highlightColorImg forState:UIControlStateHighlighted];
}

- (void)drawRect:(CGRect)rect {
    CGRect r2;
    
    float a = MIN(rect.size.height, rect.size.width);
    r2.origin.x = rect.origin.x + 1.0f;
    if (rect.size.width > a) {
        r2.origin.x += (rect.size.width - a) / 2.0f;
    }
    r2.origin.y = rect.origin.y + 1.0f;
    if (rect.size.height > a) {
        r2.origin.y += (rect.size.height - a) / 2.0f;
    }

    r2.size.height = a - 2.0f;
    r2.size.width = a - 2.0f;
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextAddEllipseInRect(ctx, r2);
    CGContextSetFillColor(ctx, CGColorGetComponents([self.fillColor CGColor]));
    CGContextSetStrokeColor(ctx, CGColorGetComponents([self.borderColor CGColor]));
    CGContextSetLineWidth(ctx, 1.0f);
    CGContextDrawPath(ctx, kCGPathFillStroke);

	if (self.clearColor) { // draw an "X" to indicate clear color
		CGFloat p = 2.0f / 7.0f * r2.size.height;
		CGContextMoveToPoint(ctx, r2.origin.x + p, r2.origin.y + p);
		CGContextAddLineToPoint(ctx, r2.origin.x + r2.size.width - p, r2.origin.y + r2.size.height - p);
		
		CGContextMoveToPoint(ctx, r2.origin.x + p, r2.origin.y + r2.size.height - p);
		CGContextAddLineToPoint(ctx, r2.origin.x + r2.size.width - p, r2.origin.y + p);
		
		CGContextSetLineWidth(ctx, 3.0f);
		CGContextDrawPath(ctx, kCGPathStroke);
	}
}

@end
