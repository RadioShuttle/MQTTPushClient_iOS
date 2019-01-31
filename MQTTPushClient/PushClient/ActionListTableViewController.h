/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <UIKit/UIKit.h>

@protocol ActionListDelegate <NSObject>
- (void)actionSent;
@end

@interface ActionListTableViewController : UITableViewController

@property Account *account;
@property BOOL editAllowed;
@property id<ActionListDelegate> delegate;

@end
