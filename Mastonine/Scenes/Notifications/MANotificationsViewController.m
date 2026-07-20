#import "MANotificationsViewController.h"
#import "MANotificationTableViewCell.h"
#import "MAAPIClient.h"
#import "MANotification.h"
#import "MAStatus.h"
#import "MAAccount.h"
#import "MALoadingView.h"
#import "MATheme.h"
#import "MAThreadViewController.h"
#import "MAProfileViewController.h"
#import "MAEmptyStateView.h"

static NSString *const kLastSeenNotifKey = @"MAMaxNotificationID";

@interface MANotificationsViewController ()

@property (nonatomic, strong) UISegmentedControl *filterControl;
@property (nonatomic, strong) NSString *currentFilter;
@property (nonatomic, copy) NSString *lastSeenID;
@property (nonatomic, strong) MAEmptyStateView *emptyView;

@end

@implementation MANotificationsViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _notifications = [NSMutableArray array];
        _lastSeenID = [[NSUserDefaults standardUserDefaults] stringForKey:kLastSeenNotifKey] ?: @"";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Notifications";
    self.view.backgroundColor = [MATheme backgroundColor];
    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 100;

    [self.tableView registerClass:[MANotificationTableViewCell class] forCellReuseIdentifier:@"NotificationCell"];

    UIRefreshControl *rc = [[UIRefreshControl alloc] init];
    rc.tintColor = [MATheme primaryColor];
    [rc addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = rc;

    [self setupFilterBar];
    [self setupNavButtons];

    _emptyView = [[MAEmptyStateView alloc] initWithIcon:@"!" title:@"No Notifications" subtitle:@"Interactions with your posts will appear here"];
    CGFloat headerHeight = 52;
    _emptyView.frame = CGRectMake(0, headerHeight, self.view.bounds.size.width, self.view.bounds.size.height - headerHeight);
    _emptyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _emptyView.hidden = YES;
    [self.view addSubview:_emptyView];

    [self loadNotifications];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewNotification:) name:@"MANewNotification" object:nil];
}

- (void)updateEmptyState {
    self.emptyView.hidden = (_notifications.count > 0);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshBadge];
}

- (void)handleNewNotification:(NSNotification *)note {
    [self refreshBadge];
}

- (void)refreshBadge {
    [[MAAPIClient sharedClient] fetchNotificationsSince:nil types:nil completion:^(NSArray *notifications, NSError *error) {
        if (error || notifications.count == 0) {
            [self updateBadgeCount:0];
            return;
        }

        NSInteger unread = 0;
        for (MANotification *n in notifications) {
            if (self->_lastSeenID.length == 0 || [n.notificationID compare:self->_lastSeenID options:NSNumericSearch] == NSOrderedDescending) {
                unread++;
            }
        }
        [self updateBadgeCount:unread];
    }];
}

- (void)setupFilterBar {
    _filterControl = [[UISegmentedControl alloc] initWithItems:@[@"All", @"Mentions", @"Boosts", @"Favourites", @"Follows"]];
    _filterControl.translatesAutoresizingMaskIntoConstraints = NO;
    _filterControl.selectedSegmentIndex = 0;
    _filterControl.tintColor = [MATheme primaryColor];
    [_filterControl addTarget:self action:@selector(filterChanged) forControlEvents:UIControlEventValueChanged];

    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 52)];
    headerContainer.backgroundColor = [MATheme backgroundColor];
    _filterControl.frame = CGRectMake(16, 8, 0, 36);
    _filterControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [headerContainer addSubview:_filterControl];
    self.tableView.tableHeaderView = headerContainer;

    [NSLayoutConstraint activateConstraints:@[
        [_filterControl.leadingAnchor constraintEqualToAnchor:headerContainer.leadingAnchor constant:16],
        [_filterControl.trailingAnchor constraintEqualToAnchor:headerContainer.trailingAnchor constant:-16],
        [_filterControl.centerYAnchor constraintEqualToAnchor:headerContainer.centerYAnchor],
    ]];
}

- (void)setupNavButtons {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Mark Read"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(markAllReadTapped)];
}

- (void)filterChanged {
    NSArray *filters = @[@"", @"mention", @"reblog", @"favourite", @"follow"];
    _currentFilter = filters[_filterControl.selectedSegmentIndex];
    [self loadNotifications];
}

- (NSString *)filterTypeParam {
    if (_currentFilter.length == 0) return nil;
    return _currentFilter;
}

#pragma mark - Data

- (void)loadNotifications {
    NSArray *types = [self filterTypeParam] ? @[[self filterTypeParam]] : nil;

    [[MAAPIClient sharedClient] fetchNotificationsSince:nil types:types completion:^(NSArray *notifications, NSError *error) {
        [self.refreshControl endRefreshing];
        if (error) return;

        self->_notifications = [notifications mutableCopy];
        if (notifications.count > 0) {
            MANotification *first = notifications.firstObject;
            self->_maxID = first.notificationID;
        }

        if (types == nil && notifications.count > 0) {
            MANotification *first = notifications.firstObject;
            NSString *newID = first.notificationID;
            if (newID.length > 0 && [newID compare:self->_lastSeenID options:NSNumericSearch] == NSOrderedDescending) {
                [[NSUserDefaults standardUserDefaults] setObject:newID forKey:kLastSeenNotifKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                self->_lastSeenID = newID;
                [self updateBadgeCount:0];
            }
        }

        [self.tableView reloadData];
        [self updateEmptyState];
    }];
}

- (void)refresh {
    NSArray *types = [self filterTypeParam] ? @[[self filterTypeParam]] : nil;

    [[MAAPIClient sharedClient] fetchNotificationsSince:nil types:types completion:^(NSArray *notifications, NSError *error) {
        [self.refreshControl endRefreshing];
        if (error) return;

        self->_notifications = [notifications mutableCopy];

        if (types == nil && notifications.count > 0) {
            MANotification *first = notifications.firstObject;
            NSString *newID = first.notificationID;
            if (newID.length > 0 && [newID compare:self->_lastSeenID options:NSNumericSearch] == NSOrderedDescending) {
                [[NSUserDefaults standardUserDefaults] setObject:newID forKey:kLastSeenNotifKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                self->_lastSeenID = newID;
                [self updateBadgeCount:0];
            }
        }

        [self.tableView reloadData];
        [self updateEmptyState];
    }];
}

- (void)loadMore {
    if (_isLoading || !_maxID) return;
    _isLoading = YES;

    NSArray *types = [self filterTypeParam] ? @[[self filterTypeParam]] : nil;

    [[MAAPIClient sharedClient] fetchNotificationsSince:_maxID types:types completion:^(NSArray *notifications, NSError *error) {
        self->_isLoading = NO;
        if (error || notifications.count == 0) return;

        [self->_notifications addObjectsFromArray:notifications];
        if (notifications.count > 0) {
            MANotification *last = notifications.lastObject;
            self->_maxID = last.notificationID;
        }
        [self.tableView reloadData];
    }];
}

#pragma mark - Mark All Read

- (void)markAllReadTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Mark All as Read"
                                                                  message:@"Clear all notification badges?"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Mark Read" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        if (self->_notifications.count > 0) {
            MANotification *first = self->_notifications.firstObject;
            NSString *newID = first.notificationID;
            if (newID.length > 0) {
                [[NSUserDefaults standardUserDefaults] setObject:newID forKey:kLastSeenNotifKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                self->_lastSeenID = newID;
                [self updateBadgeCount:0];
            }
        }

        [[MAAPIClient sharedClient] clearNotificationsWithCompletion:^(NSError *error) {
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->_notifications removeAllObjects];
                    [self.tableView reloadData];
                });
            }
        }];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Badge

- (void)updateBadgeCount:(NSInteger)count {
    UITabBarItem *tabBarItem = self.navigationController.tabBarItem;
    if (count > 0) {
        tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)count];
    } else {
        tabBarItem.badgeValue = nil;
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MANotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationCell" forIndexPath:indexPath];
    MANotification *notification = _notifications[indexPath.row];
    [cell configureWithNotification:notification];

    if (_lastSeenID.length > 0 && [notification.notificationID compare:_lastSeenID options:NSNumericSearch] != NSOrderedDescending) {
        cell.contentView.alpha = 0.5;
    } else {
        cell.contentView.alpha = 1.0;
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (NSInteger)_notifications.count - 5) {
        [self loadMore];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    MANotification *notification = _notifications[indexPath.row];

    if (_lastSeenID.length > 0 && [notification.notificationID compare:_lastSeenID options:NSNumericSearch] == NSOrderedDescending) {
        NSInteger unreadCount = 0;
        for (MANotification *n in _notifications) {
            if ([n.notificationID compare:_lastSeenID options:NSNumericSearch] == NSOrderedDescending) {
                unreadCount++;
            }
        }
        unreadCount--;
        if (unreadCount < 0) unreadCount = 0;
        [self updateBadgeCount:unreadCount];
    }

    switch (notification.type) {
        case MANotificationTypeMention:
        case MANotificationTypeReblog:
        case MANotificationTypeFavourite: {
            if (notification.status) {
                MAThreadViewController *thread = [[MAThreadViewController alloc] initWithStatusID:notification.status.statusID];
                [self.navigationController pushViewController:thread animated:YES];
            }
            break;
        }
        case MANotificationTypeFollow: {
            if (notification.account) {
                MAProfileViewController *profile = [[MAProfileViewController alloc] initWithAccountID:notification.account.accountID];
                [self.navigationController pushViewController:profile animated:YES];
            }
            break;
        }
        case MANotificationTypeFollowRequest: {
            if (notification.account) {
                UIAlertController *sheet = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Follow request from @%@", notification.account.username]
                                                                              message:nil
                                                                       preferredStyle:UIAlertControllerStyleActionSheet];
                [sheet addAction:[UIAlertAction actionWithTitle:@"Authorize" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                    [[MAAPIClient sharedClient] acceptFollowRequest:notification.account.accountID completion:^(NSError *error) {
                        if (!error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self->_notifications removeObjectAtIndex:indexPath.row];
                                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                            });
                        }
                    }];
                }]];
                [sheet addAction:[UIAlertAction actionWithTitle:@"Reject" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
                    [[MAAPIClient sharedClient] rejectFollowRequest:notification.account.accountID completion:^(NSError *error) {
                        if (!error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self->_notifications removeObjectAtIndex:indexPath.row];
                                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                            });
                        }
                    }];
                }]];
                [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    sheet.modalPresentationStyle = UIModalPresentationPopover;
                    sheet.popoverPresentationController.sourceView = [tableView cellForRowAtIndexPath:indexPath];
                    sheet.popoverPresentationController.sourceRect = [tableView cellForRowAtIndexPath:indexPath].bounds;
                }

                [self presentViewController:sheet animated:YES completion:nil];
            }
            break;
        }
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

@end
