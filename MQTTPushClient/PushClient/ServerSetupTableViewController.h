/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <UIKit/UIKit.h>
#import "AccountList.h"

@interface ServerSetupTableViewController : UITableViewController

@property AccountList *accountList;

// Index of account to edit (in accountList), -1 for creating a new account.
@property NSInteger editIndex;

@end
