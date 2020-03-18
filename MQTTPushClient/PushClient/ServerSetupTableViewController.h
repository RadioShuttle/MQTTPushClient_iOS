/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "AccountList.h"

@interface ServerSetupTableViewController : UITableViewController

@property AccountList *accountList;

// Index of account to edit (in accountList), -1 for creating a new account.
@property NSInteger editIndex;

@end
