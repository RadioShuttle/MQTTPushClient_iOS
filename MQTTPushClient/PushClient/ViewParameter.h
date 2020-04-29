/*
 * Copyright (c) 2020 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/*
 * A `ViewParameter` object is passed as `view` argument to the `filterMsg`
 * JavaScript function and exposes the following JavaScript functions:
 *
 *	function setTextColor(color)
 *	function setBackgroundColor(color)
 *	function getTextColor()
 *	function getBackgroundColor()
 */

typedef NS_ENUM(uint64_t, DColor) {
	DColorOSDefault = 0x0100000000LL,
	DColorClear     = 0x0200000000LL
};

@interface ViewParameter : NSObject

@property int64_t currentTextColor;
@property int64_t currentBackgroundColor;

// Current colors as UIColor:
@property(nullable, readonly) UIColor *uiTextColor;
@property(nullable, readonly) UIColor *uiBackgroundColor;
@end

NS_ASSUME_NONNULL_END
