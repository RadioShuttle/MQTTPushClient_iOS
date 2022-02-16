/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "JavaScriptFilter.h"
#import "Topic.h"
#import "Account.h"
#import "ScriptViewController.h"
#import "ScriptListTableViewController.h"
#import "ScriptViewSectionHeader.h"
#import "CDMessage+CoreDataClass.h"
#import "Trace.h"

@import SafariServices;

@interface ScriptViewController () <UITextViewDelegate, ScriptListDelegate>

@property (weak, nonatomic) IBOutlet UITextView *scriptTextView;
@property (weak, nonatomic) IBOutlet UITextView *testMessageTextView;
@property (weak, nonatomic) IBOutlet UILabel *functionMsgLabel;
@property (weak, nonatomic) IBOutlet UILabel *functionReturnLabel;
@property (weak, nonatomic) IBOutlet UITextView *testMsgLabel;

@property(copy) NSString *statusMessage;
@property(nullable, copy) NSData *testData;
@property(nullable) ViewParameter *viewParameter;
@end

@implementation ScriptViewController

- (IBAction)testScript:(UIButton *)sender {
	NSError *error = nil;
	NSString *msg = self.testMessageTextView.text;
	
	// Use the original binary data from the test message if the "Test Data" field
	// was not edited, otherwise the given test message as UTF-8 data.
	NSData *testData = self.testData;
	if (testData == nil) {
		testData = [msg dataUsingEncoding:NSUTF8StringEncoding];
	}
	
	ViewParameter *viewParameter = [[ViewParameter alloc] init];
	JavaScriptFilter *filter = [[JavaScriptFilter alloc] initWithScript:self.scriptTextView.text];
	NSObject *raw = [filter arrayBufferFromData:testData];
	NSDictionary *arg1 = @{@"raw":raw, @"text":msg, @"topic":self.topic.name, @"receivedDate":[NSDate date]};
	NSDictionary *arg2 = @{@"user":self.account.mqttUser, @"mqttServer":self.account.mqttHost, @"pushServer":self.account.host};
	NSString *filtered = [filter filterMsg:arg1 acc:arg2
							  viewParameter:viewParameter
									 error:&error];
	if (filtered) {
		self.statusMessage = [@"JavaScript result:\n" stringByAppendingString:[filtered stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		self.viewParameter = viewParameter;
	} else {
		self.statusMessage = [@"JavaScript error:\n" stringByAppendingString:error.localizedDescription];
		self.viewParameter = nil;
	}
	[self.tableView reloadData]; // Force update and resize of section header view.
}

- (void)updateDynamicType {
	UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1];
	UIFont *courier = [UIFont fontWithName:@"Courier" size:fontDescriptor.pointSize];
	self.functionMsgLabel.font = courier;
	self.functionMsgLabel.adjustsFontForContentSizeCategory = YES;
	self.scriptTextView.font = courier;
	self.scriptTextView.adjustsFontForContentSizeCategory = YES;
	self.functionReturnLabel.font = courier;
	self.functionReturnLabel.adjustsFontForContentSizeCategory = YES;
	self.testMsgLabel.font = courier;
	self.testMsgLabel.adjustsFontForContentSizeCategory = YES;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self updateDynamicType];
	self.scriptTextView.text = self.topic.filterScriptEdited;
	self.statusMessage = [NSString stringWithFormat:@"Filter the content of all messages with the topic %@", self.topic.name];
	
	UINib *nib = [UINib nibWithNibName:@"ScriptViewSectionHeader" bundle:nil];
	[self.tableView registerNib:nib forHeaderFooterViewReuseIdentifier:@"IDScriptViewSectionHeader"];
	
	[self setTestMessage];
	
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardNotification:)
												 name:UIKeyboardDidShowNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(contentSizeCategoryDidChangeNotification:)
												 name:UIContentSizeCategoryDidChangeNotification
											   object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.topic.filterScriptEdited = self.scriptTextView.text;
}

- (void)setTestMessage {
	/*
	 * Set test message to text of newest message of this account with the same topic.
	 */
	NSFetchRequest<CDMessage *> *fetchRequest = CDMessage.fetchRequest;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account = %@ AND topic = %@",
							  self.account.cdaccount, self.topic.name];
	fetchRequest.predicate = predicate;
	fetchRequest.fetchLimit = 1;
	NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
	NSSortDescriptor *sort2 = [[NSSortDescriptor alloc] initWithKey:@"messageID" ascending:NO];
	fetchRequest.sortDescriptors = @[sort1, sort2];
	NSArray<CDMessage *> *messages = [self.account.context executeFetchRequest:fetchRequest error:nil];
	if (messages.count > 0) {
		self.testData = messages.firstObject.content;
		self.testMessageTextView.text = [Message msgFromData:messages.firstObject.content];
	} else {
		self.testMessageTextView.text = @"";
	}
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
	header.statusLabel.backgroundColor = self.viewParameter.uiBackgroundColor;
	header.statusLabel.textColor = self.viewParameter.uiTextColor;
	return header;
}

- (void)textViewDidChange:(UITextView *)textView {
	// The height of the script editor text field might have changed.
	// Make the table view resize its cells, if necessary.
	[UIView setAnimationsEnabled:NO];
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
	[UIView setAnimationsEnabled:YES];
	
	if (textView == self.testMsgLabel) {
		self.testData = nil;
	}
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
	[self scrollToInsertionPointOf:textView];
}

- (void)keyboardNotification:(NSNotification*)notification {
	if (self.scriptTextView.isFirstResponder) {
		[self scrollToInsertionPointOf:self.scriptTextView];
	} else if (self.testMessageTextView.isFirstResponder) {
		[self scrollToInsertionPointOf:self.testMessageTextView];
	}
}

- (void)contentSizeCategoryDidChangeNotification:(NSNotification*)notification {
	[self updateDynamicType];
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
		NSString *urlString = @"https://help.radioshuttle.de/mqttapp/1.0/en/filter-scripts.html?client=iOS";
		if ([[[NSLocale preferredLanguages] firstObject] hasPrefix:@"de"]) {
			urlString = @"https://help.radioshuttle.de/mqttapp/1.0/de/filter-scripts.html?client=iOS";
		}
		NSURL *url = [NSURL URLWithString:urlString];
		SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
		if (@available(iOS 13.0, *)) {
			safariViewController.preferredBarTintColor = [UIColor systemBackgroundColor];
			safariViewController.preferredControlTintColor = self.view.tintColor;
		}
		[self presentViewController:safariViewController animated:YES completion:^{}];
	}];
}


@end
