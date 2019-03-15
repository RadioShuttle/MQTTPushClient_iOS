/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
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
