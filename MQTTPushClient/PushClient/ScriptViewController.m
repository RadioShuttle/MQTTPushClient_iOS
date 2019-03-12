/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "JavaScriptFilter.h"
#import "Topic.h"
#import "Account.h"
#import "ScriptViewController.h"
#import "ScriptListTableViewController.h"
#import "ScriptViewSectionHeader.h"
#import "Trace.h"
@import SafariServices;

@interface ScriptViewController () <UITextViewDelegate, ScriptListDelegate>

@property (weak, nonatomic) IBOutlet UITextView *scriptTextView;
@property (weak, nonatomic) IBOutlet UITextView *testMessageTextView;

@property NSString *statusMessage;

@end

@implementation ScriptViewController

- (IBAction)testScript:(UIButton *)sender {
	NSError *error = nil;
	NSString *msg = self.testMessageTextView.text;
	char *bytes = (char *)[msg UTF8String];
	NSUInteger n = msg.length;
	NSMutableArray *raw = [[NSMutableArray alloc] initWithCapacity:n];
	for (int i = 0; i < n; i++)
		raw[i] = [NSNumber numberWithUnsignedChar:bytes[i]];
	NSDictionary *arg1 = @{@"raw":raw, @"text":msg, @"topic":self.topic.name, @"receivedDate":[NSDate date]};
	NSDictionary *arg2 = @{@"user":self.account.mqttUser, @"mqttServer":self.account.mqttHost, @"pushServer":self.account.host};
	JavaScriptFilter *filter = [[JavaScriptFilter alloc] initWithScript:self.scriptTextView.text];
	NSString *filtered = [filter filterMsg:arg1 acc:arg2 error:&error];
	if (filtered)
		self.statusMessage = [filtered stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	else
		self.statusMessage = error.localizedDescription;
	[self.tableView reloadData]; // Force update and resize of section header view.
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.scriptTextView.text = self.topic.filterScript;
	self.statusMessage = [NSString stringWithFormat:@"Edit filter script for topic “%@”", self.topic.name];
	
	UINib *nib = [UINib nibWithNibName:@"ScriptViewSectionHeader" bundle:nil];
	[self.tableView registerNib:nib forHeaderFooterViewReuseIdentifier:@"IDScriptViewSectionHeader"];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.testMessageTextView.text = @"Hello";
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

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
	return 20.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return UITableViewAutomaticDimension;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	ScriptViewSectionHeader *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"IDScriptViewSectionHeader"];
	header.statusLabel.text = self.statusMessage;
	return header;
}

- (void)textViewDidChange:(UITextView *)textView {
	// The height of the script editor text field might have changed.
	// Make the table view resize its cells, if necessary.
	[UIView setAnimationsEnabled:NO];
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
	[UIView setAnimationsEnabled:YES];
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
	[self scrollToInsertionPointOf:self.scriptTextView];
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
