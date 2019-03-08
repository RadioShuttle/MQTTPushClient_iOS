/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Topic.h"
#import "ScriptViewController.h"
#import "Trace.h"

@interface ScriptViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *scriptTextView;

@end

@implementation ScriptViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.scriptTextView.text = self.topic.filterScript;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardNotification:)
												 name:UIKeyboardDidShowNotification
											   object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIKeyboardDidShowNotification
												  object:nil];
}

- (void)textViewDidChange:(UITextView *)textView {
	if (textView == self.scriptTextView) {
		// The height of the script editor text field might have changed.
		// Make the table view resize its cells, if necessary.
		[UIView setAnimationsEnabled:NO];
		[self.tableView beginUpdates];
		[self.tableView endUpdates];
		[UIView setAnimationsEnabled:YES];
	}
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
	if (textView == self.scriptTextView) {
		[self scrollToInsertionPointOf:self.scriptTextView];
	}
}

- (void)keyboardNotification:(NSNotification*)notification {
	[self scrollToInsertionPointOf:self.scriptTextView];
}

// Scroll table view – if necessary – to make the current insertion point
// (caret) of the text field visible.
- (void)scrollToInsertionPointOf:(UITextView *)textView {
	if (textView.isFirstResponder) {
		UITextRange *range = textView.selectedTextRange;
		if (range != nil) {
			// Workaround from https://stackoverflow.com/a/26280994 :
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
						   dispatch_get_main_queue(), ^{
							   UITextPosition *pos = range.end;
							   UITextPosition *start = textView.beginningOfDocument;
							   UITextPosition *end = textView.endOfDocument;
							   if ([textView comparePosition:start toPosition: pos] != NSOrderedDescending
								   && [textView comparePosition:pos toPosition: end] != NSOrderedDescending) {
								   
								   CGRect r1 = [textView caretRectForPosition:range.end];
								   CGRect r2 = [textView convertRect:r1 toView:self.tableView];
								   [self.tableView scrollRectToVisible:r2 animated:NO];
							   }
						   });
		}
	}
}

@end
