/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "ScriptListTableViewController.h"

@interface ScriptListTableViewController ()

@property NSArray<NSDictionary<NSString *, NSString *> *> *scripts;

@end

@implementation ScriptListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSURL *listURL = [[NSBundle mainBundle] URLForResource:@"ExampleScripts" withExtension:@"plist"];
	self.scripts = [NSArray arrayWithContentsOfURL:listURL];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
        case 1:
            return self.scripts.count;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IDScriptCell" forIndexPath:indexPath];
    
    NSString *text = @"";
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    text = @"Clear";
                    break;
                case 1:
                    text = @"Help";
                    break;
            }
			break;
        case 1:
			text = self.scripts[indexPath.row][@"label"];
			break;
    }
	cell.textLabel.text = text;

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 1:
			return @"Insert Example";
		default:
			return @"";
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
					[self.delegate clearScript];
					break;
				case 1:
					[self.delegate showScriptHelp];
					break;
			}
			break;
		case 1: {
			NSString *scriptName = self.scripts[indexPath.row][@"script"];
			NSURL *scriptURL = [[NSBundle mainBundle] URLForResource:scriptName withExtension:nil];
			NSString *scriptText = [NSString stringWithContentsOfURL:scriptURL
															encoding:NSUTF8StringEncoding error:NULL];
			if (scriptText.length > 0) {
				[self.delegate insertScript:scriptText];
			}
		}
			break;
	}
}

#pragma mark - ScriptListDelegate methods

- (IBAction)doneAction:(UIBarButtonItem *)sender {
	[self.delegate insertScript:nil];
}
@end
