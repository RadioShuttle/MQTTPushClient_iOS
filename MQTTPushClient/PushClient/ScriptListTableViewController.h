/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>

@protocol ScriptListDelegate <NSObject>

- (void)clearScript;
- (void)insertScript:(nullable NSString *)scriptText;
- (void)showScriptHelp;

@end

NS_ASSUME_NONNULL_BEGIN

@interface ScriptListTableViewController : UITableViewController

@property (weak) id<ScriptListDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
