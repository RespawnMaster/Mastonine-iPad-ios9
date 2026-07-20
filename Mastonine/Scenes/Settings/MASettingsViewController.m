#import "MASettingsViewController.h"
#import "MAAPIClient.h"
#import "MAAccount.h"
#import "MAImageCache.h"
#import "MATheme.h"
#import "MAMainTabBarController.h"
#import "MAGlobalTimelineViewController.h"
#import "MABookmarksViewController.h"
#import "MAListsViewController.h"
#import "MAExploreViewController.h"
#import "MAProfileViewController.h"
#import "MAFavouritesViewController.h"
#import "MADraftsViewController.h"
#import "MAScheduledPostsViewController.h"
#import "MAFiltersViewController.h"
#import "MASpotlightIndexer.h"
#import "MAAccountListViewController.h"

@interface MASettingsViewController ()
@property (nonatomic, assign) BOOL pushFollow;
@property (nonatomic, assign) BOOL pushFavourite;
@property (nonatomic, assign) BOOL pushReblog;
@property (nonatomic, assign) BOOL pushMention;
@end

@implementation MASettingsViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
    self.view.backgroundColor = [MATheme backgroundColor];
    self.tableView.backgroundColor = [MATheme backgroundColor];

    self.tableView.tableFooterView = [[UIView alloc] init];

    _pushFollow = [[[NSUserDefaults standardUserDefaults] objectForKey:@"push_follow"] boolValue];
    _pushFavourite = [[[NSUserDefaults standardUserDefaults] objectForKey:@"push_favourite"] boolValue];
    _pushReblog = [[[NSUserDefaults standardUserDefaults] objectForKey:@"push_reblog"] boolValue];
    _pushMention = [[[NSUserDefaults standardUserDefaults] objectForKey:@"push_mention"] boolValue];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 2;
        case 1: return 1;
        case 2: return 5;
        case 3: return 2;
        case 4: return 4;
        case 5: return 4;
        case 6: return 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"Timelines";
        case 1: return @"Appearance";
        case 2: return @"Discover";
        case 3: return @"Content";
        case 4: return @"Account";
        case 5: return @"Push Notifications";
        case 6: return @"About";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"SettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
        cell.backgroundColor = [MATheme cardColor];
        cell.textLabel.textColor = [MATheme textColor];
        cell.detailTextLabel.textColor = [MATheme secondaryTextColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        UIView *bgView = [[UIView alloc] init];
        bgView.backgroundColor = [MATheme primaryDarkColor];
        cell.selectedBackgroundView = bgView;
    }

    cell.textLabel.textColor = [MATheme textColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0: cell.textLabel.text = @"Local Timeline"; break;
            case 1: cell.textLabel.text = @"Federated Timeline"; break;
        }
    } else if (indexPath.section == 1) {
        cell.textLabel.text = @"Dark Mode";
        UISwitch *toggle = [[UISwitch alloc] init];
        toggle.on = [MATheme isDarkMode];
        toggle.onTintColor = [MATheme primaryColor];
        [toggle addTarget:self action:@selector(darkModeToggled:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0: cell.textLabel.text = @"Explore / Trending"; break;
            case 1: cell.textLabel.text = @"Lists"; break;
            case 2: cell.textLabel.text = @"Bookmarks"; break;
            case 3: cell.textLabel.text = @"Scheduled Posts"; break;
            case 4: cell.textLabel.text = @"Favourites"; break;
        }
    } else if (indexPath.section == 3) {
        switch (indexPath.row) {
            case 0: cell.textLabel.text = @"Drafts"; break;
            case 1: cell.textLabel.text = @"Content Filters"; break;
        }
    } else if (indexPath.section == 4) {
        switch (indexPath.row) {
            case 0: cell.textLabel.text = @"My Profile"; break;
            case 1: cell.textLabel.text = @"Blocked Users"; break;
            case 2: cell.textLabel.text = @"Muted Users"; break;
            case 3: cell.textLabel.text = @"Sign Out";
                cell.textLabel.textColor = [MATheme dangerColor]; break;
        }
    } else if (indexPath.section == 5) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        UISwitch *toggle = [[UISwitch alloc] init];
        toggle.onTintColor = [MATheme primaryColor];
        [toggle addTarget:self action:@selector(pushSettingChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
        switch (indexPath.row) {
            case 0: cell.textLabel.text = @"Follows"; toggle.on = _pushFollow; toggle.tag = 0; break;
            case 1: cell.textLabel.text = @"Favourites"; toggle.on = _pushFavourite; toggle.tag = 1; break;
            case 2: cell.textLabel.text = @"Reblogs"; toggle.on = _pushReblog; toggle.tag = 2; break;
            case 3: cell.textLabel.text = @"Mentions"; toggle.on = _pushMention; toggle.tag = 3; break;
        }
    } else {
        cell.textLabel.text = @"Mastonine v1.0";
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.text = @"Native iOS 9 Client";
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0: {
                MAGlobalTimelineViewController *local = [[MAGlobalTimelineViewController alloc] initWithTimelineType:@"local"];
                [self.navigationController pushViewController:local animated:YES];
                break;
            }
            case 1: {
                MAGlobalTimelineViewController *federated = [[MAGlobalTimelineViewController alloc] initWithTimelineType:@"federated"];
                [self.navigationController pushViewController:federated animated:YES];
                break;
            }
        }
    } else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0: {
                MAExploreViewController *explore = [[MAExploreViewController alloc] initWithStyle:UITableViewStylePlain];
                [self.navigationController pushViewController:explore animated:YES];
                break;
            }
            case 1: {
                MAListsViewController *lists = [[MAListsViewController alloc] initWithStyle:UITableViewStylePlain];
                [self.navigationController pushViewController:lists animated:YES];
                break;
            }
            case 2: {
                MABookmarksViewController *bookmarks = [[MABookmarksViewController alloc] initWithStyle:UITableViewStylePlain];
                [self.navigationController pushViewController:bookmarks animated:YES];
                break;
            }
            case 3: {
                MAScheduledPostsViewController *scheduled = [[MAScheduledPostsViewController alloc] initWithStyle:UITableViewStylePlain];
                [self.navigationController pushViewController:scheduled animated:YES];
                break;
            }
            case 4: {
                MAFavouritesViewController *favs = [[MAFavouritesViewController alloc] initWithStyle:UITableViewStylePlain];
                [self.navigationController pushViewController:favs animated:YES];
                break;
            }
        }
    } else if (indexPath.section == 3) {
        switch (indexPath.row) {
            case 0: {
                MADraftsViewController *drafts = [[MADraftsViewController alloc] initWithStyle:UITableViewStylePlain];
                [self.navigationController pushViewController:drafts animated:YES];
                break;
            }
            case 1: {
                MAFiltersViewController *filters = [[MAFiltersViewController alloc] initWithStyle:UITableViewStyleGrouped];
                [self.navigationController pushViewController:filters animated:YES];
                break;
            }
        }
    } else if (indexPath.section == 4) {
        switch (indexPath.row) {
            case 0: {
                MAProfileViewController *profile = [[MAProfileViewController alloc] initWithStyle:UITableViewStylePlain];
                [self.navigationController pushViewController:profile animated:YES];
                break;
            }
            case 1: {
                MAAccountListViewController *blocked = [[MAAccountListViewController alloc] initWithBlocked];
                [self.navigationController pushViewController:blocked animated:YES];
                break;
            }
            case 2: {
                MAAccountListViewController *muted = [[MAAccountListViewController alloc] initWithMuted];
                [self.navigationController pushViewController:muted animated:YES];
                break;
            }
            case 3: {
                [self signOut];
                break;
            }
        }
    }
}

- (void)signOut {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sign Out"
                                                                  message:@"Are you sure you want to sign out?"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Sign Out" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"instance_url"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"access_token"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"client_id"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"client_secret"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [MAImageCache.sharedCache clearCache];
        [MASpotlightIndexer removeAll];

        exit(0);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)darkModeToggled:(UISwitch *)sender {
    [MATheme setDarkMode:sender.isOn];
    exit(0);
}

- (void)pushSettingChanged:(UISwitch *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL value = sender.isOn;
    NSString *key;
    switch (sender.tag) {
        case 0: key = @"push_follow"; _pushFollow = value; break;
        case 1: key = @"push_favourite"; _pushFavourite = value; break;
        case 2: key = @"push_reblog"; _pushReblog = value; break;
        case 3: key = @"push_mention"; _pushMention = value; break;
    }
    if (key) {
        [defaults setBool:value forKey:key];
        [defaults synchronize];
    }

    NSDictionary *alerts = @{
        @"follow": @(_pushFollow),
        @"favourite": @(_pushFavourite),
        @"reblog": @(_pushReblog),
        @"mention": @(_pushMention),
        @"poll": @NO,
    };
    [[MAAPIClient sharedClient] updatePushSubscriptionAlerts:alerts completion:^(NSDictionary *sub, NSError *error) {
        if (error) {
            [self.tableView reloadData];
        }
    }];
}

@end
