/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Topic.h"
#import "ScriptViewController.h"

@interface ScriptViewController ()

@property (weak, nonatomic) IBOutlet UITextView *scriptTextView;

@end

@implementation ScriptViewController

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	self.scriptTextView.text = self.topic.filterScript;
}

@end
