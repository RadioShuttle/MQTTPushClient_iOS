/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#ifndef DashConsts_h
#define DashConsts_h

// json protocol version
#define DASHBOARD_PROTOCOL_VERSION 0

// file releated
#define DASH512_PNG	@"dash512png"
#define LOCAL_IMPORTED_FILES_DIR @"images/imported"
#define LOCAL_USER_FILES_DIR @"images/user"

// colors
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define DASH_DEFAULT_CELL_COLOR 0xd7d7d7

#define DASH_COLOR_WHITE 0xffffffff
#define DASH_COLOR_LT_GRAY 0xffa0a0a0
#define DASH_COLOR_DK_GRAY 0xff575757
#define DASH_COLOR_BLACK 0xff000000
#define DASH_COLOR_TAN 0xffe9debb
#define DASH_COLOR_YELLOW 0xffffee33
#define DASH_COLOR_ORANGE 0xffff9233
#define DASH_COLOR_RED 0xffad2323
#define DASH_COLOR_BROWN 0xff814a19
#define DASH_COLOR_LT_GREEN 0xff81c57a
#define DASH_COLOR_GREEN 0xff1d6914
#define DASH_COLOR_PINK 0xffffcdf3
#define DASH_COLOR_PURPLE 0xff8126c0
#define DASH_COLOR_CYAN 0xff29d0d0
#define DASH_COLOR_LT_BLUE 0xff9dafff
#define DASH_COLOR_BLUE 0xff2a4bd7
#define DASH_COLOR_TRANSPARENT 0
#define DASH_COLOR_OS_DEFAULT 0x0100000000
#define DASH_COLOR_CLEAR 0x0200000000

// metrics
#define DASH_ZOOM_1 100.0f
#define DASH_ZOOM_2 150.0f
#define DASH_ZOOM_3 200.0f

#define DASH_DIALOG_VIEW_SIZE 250.0f

#define DASH_MAX_IMAGE_SIZE_PX 512

// other
#define DASH_TIMER_INTERVAL_SEC 5.0f
#define DASH_MAX_CONCURRENT_JS_TASKS 4
#define DASH_MAX_JS_TASKS_QUEUE_TIME 5
#define DASH_MAX_HISTORICAL_DATA_SIZE 200

#endif /* DashConsts_h */
