/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "JavaScriptFilter.h"
#import "Topic.h"
#import "Account.h"
#import "DashScriptViewController.h"
#import "ScriptViewSectionHeader.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "DashJavaScriptTask.h"

#import "Utils.h"
#import "Trace.h"
#import "MqttUtils.h"

@import SafariServices;

@interface DashScriptViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *scriptTextView;
@property (weak, nonatomic) IBOutlet UITextView *testMessageTextView;
@property (weak, nonatomic) IBOutlet UILabel *functionMsgLabel;
@property (weak, nonatomic) IBOutlet UILabel *functionReturnLabel;
@property (weak, nonatomic) IBOutlet UILabel *testMsgLabel;

@property(copy) NSString *statusMessage;
@property(nullable, copy) NSData *testData;
@property NSOperationQueue *operationQueue;

@property IBOutlet UIBarButtonItem *moreButton;

@end

@implementation DashScriptViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self updateDynamicType];
	if (self.filterScriptMode) {
		self.scriptTextView.text = self.parentCtrl.item.script_f;
		self.statusMessage = [NSString stringWithFormat:@"Filter the content of all messages with the topic %@", self.parentCtrl.item.topic_p];
	} else {
		self.functionMsgLabel.text = @"function setContent(input, msg, acc, view) {\n var msg.text = input;";
		self.functionReturnLabel.text = @" return msg;";
		self.testMsgLabel.text = @"Test Data (input):";
		self.scriptTextView.text = self.parentCtrl.item.script_p;
		self.statusMessage = @"Set content for message being published";
	}
	
	UINib *nib = [UINib nibWithNibName:@"ScriptViewSectionHeader" bundle:nil];
	[self.tableView registerNib:nib forHeaderFooterViewReuseIdentifier:@"IDScriptViewSectionHeader"];
	
	[self setTestMessage];
	
	self.moreButton.target = self;
	self.moreButton.action = @selector(onMoreButtonClicked);

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onJavaScriptTaskFinished:) name:@"DashJavaScriptTaskNotification" object:nil];
}

-(void)onMoreButtonClicked {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[alert addAction:[UIAlertAction actionWithTitle:@"Run" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self testScript:nil];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self onClearButtonClicked];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Help"  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self showScriptHelp];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[alert setModalPresentationStyle:UIModalPresentationPopover];
	alert.popoverPresentationController.barButtonItem = self.moreButton;

	[self presentViewController:alert animated:TRUE completion:nil];
}

- (void)onJavaScriptTaskFinished:(NSNotification *)notif {
	uint64_t version = [[notif.userInfo helNumberForKey:@"version"] unsignedLongLongValue];
	if (version == 0) { // ignore regular script results (test java script use version 0)
		// NSLog(@"Javascript task finished");
		NSError *error = [notif.userInfo objectForKey:@"error"];
		if (error) {
			self.statusMessage = [@"JavaScript error:\n" stringByAppendingString:error.localizedDescription];
		} else {
			NSString *filtered;
			if (self.filterScriptMode) {
				filtered = [notif.userInfo helStringForKey:@"filterMsgResult"];
			} else {
				DashMessage *msg = [notif.userInfo objectForKey:@"message"];
				filtered = [msg contentToStr];
			}
			if (filtered) {
				self.statusMessage = [@"JavaScript result:\n" stringByAppendingString:[filtered stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			}
		}
		[self.tableView reloadData]; // Force update and resize of section header view.
	}
}


-(void)onClearButtonClicked {
	if (![Utils isEmpty:self.scriptTextView.text]) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Clear JavaScript content?" preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {[self clearScript];
		}]];
		[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		}]];
		[self presentViewController:alert animated:TRUE completion:nil];
	}
}

- (IBAction)testScript:(UIButton *)sender {
	NSString *msg = self.testMessageTextView.text;
	
	// Use the original binary data from the test message if the "Test Data" field
	// was not edited, otherwise the given test message as UTF-8 data.
	NSData *testData = self.testData;
	if (testData == nil) {
		testData = [msg dataUsingEncoding:NSUTF8StringEncoding];
	}

	DashItem *item = [[self.parentCtrl getDashItem] copy];
	DashMessage *dm = [DashMessage new];
	dm.content = testData;
	dm.topic = (self.filterScriptMode ? item.topic_s : item.topic_p);
	dm.timestamp = [NSDate new];

	DashJavaScriptTask *jsTask;
	if (self.filterScriptMode) {
		item.script_f = self.scriptTextView.text;
		
		jsTask = [[DashJavaScriptTask alloc]initWithItem:item message:dm version:0 account:self.parentCtrl.parentCtrl.dashboard.account];
	} else {
		item.script_p = self.scriptTextView.text;
		
		jsTask = [[DashJavaScriptTask alloc]initWithItem:item publishData:dm version:0 account:self.parentCtrl.parentCtrl.dashboard.account requestData:nil];
	}
	if (!self.operationQueue) {
		self.operationQueue = [NSOperationQueue new];
		[self.operationQueue setMaxConcurrentOperationCount:1];
	}
	
	NSInvocationOperation *op = [[NSInvocationOperation alloc]initWithTarget:jsTask selector:@selector(execute) object:nil];
	[self.operationQueue addOperation:op];
	
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
	self.testMessageTextView.font = courier;
	self.testMessageTextView.adjustsFontForContentSizeCategory = YES;
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
	
	NSString *org;
	if (self.filterScriptMode) {
		org = self.parentCtrl.item.script_f;
	} else {
		org = self.parentCtrl.item.script_p;
	}
	NSString *code = self.scriptTextView.text;
	org = org ? org : @"";
	code = code ? code : @"";
	if (![org isEqualToString:code]) {
		if (self.filterScriptMode) {
			[self.parentCtrl onFilterScriptContentUpdated:code];
		} else {
			[self.parentCtrl onOutputScriptContentUpdated:code];
		}
	}
}

- (void)setTestMessage {
	self.testMessageTextView.text = nil;
	/*
	 * Set test message to text of newest message of this account with the same topic.
	 */
	if (self.filterScriptMode && ![Utils isEmpty:self.parentCtrl.item.topic_s]) {
		DashMessage *newestMsg = nil;
		
		NSArray<DashMessage *> *msgs = [self.parentCtrl.parentCtrl.dashboard.lastReceivedMsgs allValues];
		for(DashMessage *m in msgs){
			if ([MqttUtils topicIsMatched:self.parentCtrl.item.topic_s topic:m.topic]) {
				if (!newestMsg || [m isNewerThan:newestMsg]) {
					newestMsg = m;
				}
			}
		}
		
		if (newestMsg) {
			self.testMessageTextView.text = [newestMsg contentToStr];
			self.testData = newestMsg.content;
		}
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
	return header;
}

- (void)textViewDidChange:(UITextView *)textView {
	// The height of the script editor text field might have changed.
	// Make the table view resize its cells, if necessary.
	[UIView setAnimationsEnabled:NO];
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
	[UIView setAnimationsEnabled:YES];
	
	if (textView == self.testMessageTextView) {
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

- (void)clearScript {
	self.scriptTextView.text = @"";
	[self textViewDidChange:self.scriptTextView];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showScriptHelp {
	NSString *urlString;
	if (self.filterScriptMode) {
		urlString = @"https://help.radioshuttle.de/mqttapp/1.0/en/dashboard_scripts.html#filter_script";
		if ([[[NSLocale preferredLanguages] firstObject] hasPrefix:@"de"]) {
			urlString = @"https://help.radioshuttle.de/mqttapp/1.0/de/dashboard_scripts.html#filter_script";
		}
	} else {
		urlString = @"https://help.radioshuttle.de/mqttapp/1.0/en/dashboard_scripts.html#output_script";
		if ([[[NSLocale preferredLanguages] firstObject] hasPrefix:@"de"]) {
			urlString = @"https://help.radioshuttle.de/mqttapp/1.0/de/dashboard_scripts.html#output_script";
		}
	}
	NSURL *url = [NSURL URLWithString:urlString];
	SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
	if (@available(iOS 13.0, *)) {
		safariViewController.preferredBarTintColor = [UIColor systemBackgroundColor];
		safariViewController.preferredControlTintColor = self.view.tintColor;
	}
	[self presentViewController:safariViewController animated:YES completion:^{}];
}

@end
