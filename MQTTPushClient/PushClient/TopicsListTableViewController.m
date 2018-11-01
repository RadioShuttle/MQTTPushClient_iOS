/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "Connection.h"
#import "Topic.h"
#import "AddTopicTableViewController.h"
#import "TopicsListTableViewController.h"

@interface TopicsListTableViewController ()

@property (strong, nonatomic) IBOutlet UILabel *tableViewHeaderLabel;

@end

@implementation TopicsListTableViewController

- (void)updateList:(NSNotification *)sender {
	[self.tableView reloadData];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	dispatch_queue_t serialQueue = dispatch_queue_create("topics.list.serial.queue", NULL);
	dispatch_async(serialQueue, ^{
		[NSThread sleepForTimeInterval:0.3f];
		if (editing) {
			Topic *topic = [[Topic alloc] init];
			[self.account.topicList insertObject:topic atIndex:0];
		} else {
			if (self.account.topicList.count) {
				Topic *topic = self.account.topicList[0];
				if (topic.name == nil || topic.name.length == 0) {
					[self.account.topicList removeObjectAtIndex:0];
				}
			}
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.tableView reloadData];
		});
	});
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.tableViewHeaderLabel.text = [NSString stringWithFormat:@"%@@%@", self.account.mqttUser, self.account.mqttHost];
	self.tableView.tableHeaderView = self.tableViewHeaderLabel;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateList:) name:@"ServerUpdateNotification" object:nil];
	Connection *connection = [[Connection alloc] init];
	[connection getTopicsForAccount:self.account];
	self.editing = NO;
	self.navigationController.toolbarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.account.topicList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	if (self.editing && indexPath.row == 0) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"IDAddTopicCell" forIndexPath:indexPath];
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"IDTopicCell" forIndexPath:indexPath];
		Topic *topic = self.account.topicList[indexPath.row];
		cell.textLabel.text = topic.name;
	}
	return cell;
}

#pragma mark - Table view delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == 0)
		return UITableViewCellEditingStyleInsert;
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		Connection *connection = [[Connection alloc] init];
		Topic *topic = self.account.topicList[indexPath.row];
		[connection deleteTopicForAccount:self.account name:topic.name];
		[connection getTopicsForAccount:self.account];
	}
}

#pragma mark - navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.editing && indexPath.row == 0) {
		[self performSegueWithIdentifier:@"IDAddTopic" sender:nil];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	AddTopicTableViewController *controller = segue.destinationViewController;
	controller.account = self.account;
}

@end
