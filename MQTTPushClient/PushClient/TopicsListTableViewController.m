/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "Connection.h"
#import "Topic.h"
#import "TopicsListTableViewCell.h"
#import "AddTopicTableViewController.h"
#import "TopicsListTableViewController.h"

@interface TopicsListTableViewController ()

@property (strong, nonatomic) IBOutlet UILabel *tableViewHeaderLabel;

@end

@implementation TopicsListTableViewController

- (void)updateList:(NSNotification *)sender {
	if (!self.editing)
		self.editing = YES;
	[self.tableView reloadData];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.tableViewHeaderLabel.text = self.account.accountDescription;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.toolbarHidden = YES;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateList:) name:@"ServerUpdateNotification" object:nil];
	Connection *connection = [[Connection alloc] init];
	[connection getTopicsForAccount:self.account];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.editing)
		return 1 + self.account.topicList.count; // because of entry "add new item" in the UI
	return self.account.topicList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	TopicsListTableViewCell *topicCell;
	if (self.editing && indexPath.row == 0) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"IDAddTopicCell" forIndexPath:indexPath];
	} else {
		topicCell = [tableView dequeueReusableCellWithIdentifier:@"IDTopicCell" forIndexPath:indexPath];
		NSUInteger row = self.editing ? indexPath.row - 1 : indexPath.row; // because of entry "add new item" in the UI
		Topic *topic = self.account.topicList[row];
		topicCell.topicLabel.text = topic.name;
		switch (topic.type) {
			case NotificationBannerSound:
				topicCell.topicTypeImageView.image = [UIImage imageNamed:@"BannerSound"];
				break;
			case NotificationBanner:
				topicCell.topicTypeImageView.image = [UIImage imageNamed:@"Banner"];
				break;
			case NotificationNone:
				topicCell.topicTypeImageView.image = [UIImage imageNamed:@"NotificationNone"];
				break;
			default:
				topicCell.topicTypeImageView.image = [UIImage imageNamed:@"NotificationDisabled"];
				break;
		}
		cell = topicCell;
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
		NSUInteger row = indexPath.row - 1; // because of entry "add new item" in the UI
		Topic *topic = self.account.topicList[row];
		[connection deleteTopicForAccount:self.account name:topic.name];
		[connection getTopicsForAccount:self.account];
	}
}

#pragma mark - navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.editing) {
		if (indexPath.row == 0) {
			[self performSegueWithIdentifier:@"IDAddTopic" sender:nil];
		} else {
			NSUInteger row = indexPath.row - 1; // because of entry "add new item" in the UI
			Topic *topic = self.account.topicList[row];
			[self performSegueWithIdentifier:@"IDShowTopic" sender:topic];
		}
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	AddTopicTableViewController *controller = segue.destinationViewController;
	controller.title = @"Update Topic";
	controller.account = self.account;
	controller.topic = sender;
	if (controller.topic)
		controller.topic.filterScriptEdited = controller.topic.filterScript;
	else
		controller.title = @"Add Topic";
}

@end
