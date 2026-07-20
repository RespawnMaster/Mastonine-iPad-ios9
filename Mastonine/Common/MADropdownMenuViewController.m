#import "MADropdownMenuViewController.h"
#import "MAList.h"
#import "MATheme.h"

@implementation MADropdownMenuViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _lists = @[];
        _hashtags = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    self.preferredContentSize = CGSizeMake(280, 300);
}

- (void)reloadData {
    [self.tableView reloadData];
    [self.view layoutIfNeeded];
    CGFloat height = [self.tableView contentSize].height + 20;
    if (height < 100) height = 100;
    if (height > 500) height = 500;
    self.preferredContentSize = CGSizeMake(280, height);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.hashtagsAvailable ? 3 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    if (section == 1) return 2 + (NSInteger)self.lists.count;
    NSInteger base = 1 + (NSInteger)self.hashtags.count;
    if (self.onHashtagFeed) base += 1;
    return base;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MenuCell"];
        cell.textLabel.font = [MATheme fontWithSize:15];
        cell.textLabel.textColor = [MATheme textColor];
        cell.backgroundColor = [MATheme cardColor];
    }

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (indexPath.section == 0) {
        cell.textLabel.text = @"Home";
        if ([self.currentTimelineType isEqualToString:@"home"]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.tintColor = [MATheme primaryColor];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Create List";
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Manage Lists";
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            MAList *list = self.lists[indexPath.row - 2];
            cell.textLabel.text = list.title;
            NSString *listType = [NSString stringWithFormat:@"list/%@", list.listID];
            if ([self.currentTimelineType isEqualToString:listType]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                cell.tintColor = [MATheme primaryColor];
            }
        }
    } else {
        if (self.onHashtagFeed) {
            if (indexPath.row == 0) {
                cell.textLabel.text = self.hashtagIsFollowed ? @"Unfollow Hashtag" : @"Follow Hashtag";
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.textColor = [MATheme textColor];
            } else if (indexPath.row == 1) {
                cell.textLabel.text = @"Manage Hashtags";
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.textColor = [MATheme textColor];
            } else {
                NSInteger tagIdx = indexPath.row - 2;
                NSDictionary *tag = self.hashtags[tagIdx];
                NSString *name = tag[@"name"] ?: @"";
                cell.textLabel.text = [NSString stringWithFormat:@"#%@", name];
                cell.textLabel.textColor = [MATheme textColor];
                NSString *tagType = [NSString stringWithFormat:@"tag/%@", name];
                if ([self.currentTimelineType isEqualToString:tagType]) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    cell.tintColor = [MATheme primaryColor];
                }
            }
        } else {
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Manage Hashtags";
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.textColor = [MATheme textColor];
            } else {
                NSDictionary *tag = self.hashtags[indexPath.row - 1];
                NSString *name = tag[@"name"] ?: @"";
                cell.textLabel.text = [NSString stringWithFormat:@"#%@", name];
                cell.textLabel.textColor = [MATheme textColor];
                NSString *tagType = [NSString stringWithFormat:@"tag/%@", name];
                if ([self.currentTimelineType isEqualToString:tagType]) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    cell.tintColor = [MATheme primaryColor];
                }
            }
        }
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Timelines";
    if (section == 1) return @"Lists";
    return self.hashtagsAreTrending ? @"Trending Hashtags" : @"Followed Hashtags";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        [self.delegate dropdownMenuDidSelectHome];
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self.delegate dropdownMenuDidSelectCreateList];
        } else if (indexPath.row == 1) {
            [self.delegate dropdownMenuDidSelectManageLists];
        } else {
            MAList *list = self.lists[indexPath.row - 2];
            [self.delegate dropdownMenuDidSelectList:list];
        }
    } else {
        if (self.onHashtagFeed) {
            if (indexPath.row == 0) {
                [self.delegate dropdownMenuDidSelectFollowHashtag];
            } else if (indexPath.row == 1) {
                [self.delegate dropdownMenuDidSelectManageHashtags];
            } else {
                NSDictionary *tag = self.hashtags[indexPath.row - 2];
                NSString *name = tag[@"name"] ?: @"";
                [self.delegate dropdownMenuDidSelectHashtag:name];
            }
        } else {
            if (indexPath.row == 0) {
                [self.delegate dropdownMenuDidSelectManageHashtags];
            } else {
                NSDictionary *tag = self.hashtags[indexPath.row - 1];
                NSString *name = tag[@"name"] ?: @"";
                [self.delegate dropdownMenuDidSelectHashtag:name];
            }
        }
    }
}

@end
