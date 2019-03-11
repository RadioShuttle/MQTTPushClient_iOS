/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <JavaScriptCore/JavaScriptCore.h>
#import "Topic.h"
#import "Account.h"
#import "ScriptViewController.h"
#import "ScriptListTableViewController.h"
#import "Trace.h"
@import SafariServices;

@interface ScriptViewController () <UITextViewDelegate, ScriptListDelegate>

@property (weak, nonatomic) IBOutlet UITextView *scriptTextView;
@property (weak, nonatomic) IBOutlet UITextView *testMessageTextView;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;

@end

@implementation ScriptViewController

- (IBAction)testScript:(UIButton *)sender {
	__block NSString *msg = self.testMessageTextView.text;
	if (self.scriptTextView.text.length) {
		char *bytes = (char *)[msg UTF8String];
		NSUInteger n = msg.length;
		NSMutableArray *raw = [[NSMutableArray alloc] initWithCapacity:n];
		for (int i = 0; i < n; i++)
			raw[i] = [NSNumber numberWithUnsignedChar:bytes[i]];
		NSDictionary *arg1 = @{@"raw":raw, @"text":msg, @"topic":self.topic.name, @"receivedDate":[NSDate date]};
		NSDictionary *arg2 = @{@"user":self.account.mqttUser, @"mqttServer":self.account.mqttHost, @"pushServer":self.account.host};
		NSString *script = [NSString stringWithFormat:@"var filter = function(msg, acc) {\n%@\nreturn content;\n}\n", self.scriptTextView.text];
		dispatch_group_t group = dispatch_group_create();
		dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_group_async(group, background, ^{
			JSContext *context = [[JSContext alloc] init];
			[context evaluateScript:script];
			JSValue *function = [context objectForKeyedSubscript:@"filter"];
			JSValue *value = [function callWithArguments:@[arg1, arg2]];
			msg = [value toString];
		});
		uint64_t timeout = dispatch_time( DISPATCH_TIME_NOW, 500000000); // in nano seconds
		dispatch_group_wait(group, timeout);
	}
	self.resultLabel.text = msg;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.scriptTextView.text = self.topic.filterScript;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.testMessageTextView.text = @"Hello";
	self.resultLabel.text = @"";
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"IDScriptList"]) {
		UINavigationController *nv = segue.destinationViewController;
		ScriptListTableViewController *sltv = (ScriptListTableViewController *)nv.topViewController;
		sltv.delegate = self;
	}
}

- (void)clearScript {
	self.scriptTextView.text = @"";
	[self textViewDidChange:self.scriptTextView];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)insertScript:(NSString *)scriptText {
	if (scriptText != nil) {
		NSMutableString *text = [self.scriptTextView.text mutableCopy];
		if (text.length > 0 && ![text hasSuffix:@"\n"]) {
			[text appendString:@"\n"];
		}
		[text appendString:scriptText];
		self.scriptTextView.text = text;
		[self textViewDidChange:self.scriptTextView];
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showScriptHelp {
	[self dismissViewControllerAnimated:YES completion:^{
		// TODO: Present localized version.
		NSURL *url = [NSURL URLWithString:@"https://help.radioshuttle.de/mqttapp/1.0/en/filter-scripts.html"];
		SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
		[self presentViewController:safariViewController animated:YES completion:^{}];
	}];
}


@end
