/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Topic.h"
#import "ScriptViewController.h"

@interface ScriptViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *scriptTextView;

@end

@implementation ScriptViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.scriptTextView.text = self.topic.filterScript;
}

- (void)textViewDidChange:(UITextView *)textView {
	if (textView == self.scriptTextView) {
		[UIView setAnimationsEnabled:NO];
		[self.tableView beginUpdates];
		[self.tableView endUpdates];
		[UIView setAnimationsEnabled:YES];
	}
}

@end
