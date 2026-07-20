#import "MAFavouritesViewController.h"
#import "MAStatusTableViewCell.h"
#import "MAAPIClient.h"
#import "MAStatus.h"
#import "MAMediaAttachment.h"
#import "MALoadingView.h"
#import "MATheme.h"
#import "MAThreadViewController.h"
#import "MAProfileViewController.h"
#import "MAImageViewerController.h"
#import "MAWebViewController.h"
#import "MAAccount.h"
#import "MAComposeViewController.h"
#import "MAEmptyStateView.h"
#import "MATimelineViewController.h"

@interface MAFavouritesViewController ()

@property (nonatomic, strong) MAEmptyStateView *emptyView;

@end

@implementation MAFavouritesViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _statuses = [NSMutableArray array];
        _hasMore = YES;
        _isLoading = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Favourites";
    self.view.backgroundColor = [MATheme backgroundColor];
    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 200;

    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }

    [self.tableView registerClass:[MAStatusTableViewCell class] forCellReuseIdentifier:@"StatusCell"];

    UIRefreshControl *rc = [[UIRefreshControl alloc] init];
    rc.tintColor = [MATheme primaryColor];
    [rc addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = rc;

    _loadingView = [[MALoadingView alloc] initWithFrame:self.view.bounds];
    _loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_loadingView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusUpdated:) name:@"MAStatusUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusReply:) name:@"MAStatusReply" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAvatarTapped:) name:@"MAAvatarTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMediaTapped:) name:@"MAMediaTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLinkTapped:) name:@"MALinkTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleHashtagTapped:) name:@"MAHashtagTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMentionTapped:) name:@"MAMentionTapped" object:nil];

    _emptyView = [[MAEmptyStateView alloc] initWithIcon:@"\u2665" title:@"No Favourites" subtitle:@"Posts you favourite will appear here"];
    _emptyView.frame = self.view.bounds;
    _emptyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _emptyView.hidden = YES;
    [self.view addSubview:_emptyView];

    [self loadInitial];
}

- (void)updateEmptyState {
    self.emptyView.hidden = (_statuses.count > 0);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification Handlers

- (void)handleStatusUpdated:(NSNotification *)notif {
    MAStatus *updatedStatus = notif.userInfo[@"status"];
    if (!updatedStatus) return;

    for (NSUInteger i = 0; i < _statuses.count; i++) {
        MAStatus *existing = _statuses[i];
        if ([existing.statusID isEqualToString:updatedStatus.statusID] ||
            [existing.reblogID isEqualToString:updatedStatus.statusID]) {
            if (updatedStatus.reblogAccount && !updatedStatus.account) {
                updatedStatus.account = existing.account;
            }
            _statuses[i] = updatedStatus;
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            if ([self.tableView cellForRowAtIndexPath:path]) {
                [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
        }
    }
}

- (void)handleStatusReply:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *statusID = notif.userInfo[@"statusID"];
    if (!statusID) return;

    MAStatus *targetStatus = nil;
    for (MAStatus *s in _statuses) {
        if ([s.statusID isEqualToString:statusID]) { targetStatus = s; break; }
        if ([s.reblogID isEqualToString:statusID]) { targetStatus = s; break; }
    }
    if (!targetStatus) return;

    MAAccount *author = targetStatus.reblogAccount ?: targetStatus.account;
    MAComposeViewController *compose = [[MAComposeViewController alloc] initWithReplyToStatusID:targetStatus.statusID
                                                                                     username:author.username];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:compose];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.navigationBar.barStyle = UIBarStyleDefault;
    nav.navigationBar.translucent = NO;
    nav.navigationBar.barTintColor = [MATheme primaryColor];
    nav.navigationBar.tintColor = [UIColor whiteColor];
    nav.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)handleAvatarTapped:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *accountID = notif.userInfo[@"accountID"];
    if (!accountID) return;
    MAProfileViewController *profile = [[MAProfileViewController alloc] initWithAccountID:accountID];
    [self.navigationController pushViewController:profile animated:YES];
}

- (void)handleMediaTapped:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *statusID = notif.userInfo[@"statusID"];
    NSInteger index = [notif.userInfo[@"index"] integerValue];
    if (!statusID) return;

    for (MAStatus *s in _statuses) {
        if ([s.statusID isEqualToString:statusID] || [s.reblogID isEqualToString:statusID]) {
            NSMutableArray *urls = [NSMutableArray array];
            for (MAMediaAttachment *att in s.mediaAttachments) {
                NSString *urlStr = att.url.length > 0 ? att.url : @"";
                if (urlStr.length > 0) [urls addObject:urlStr];
            }
            if (urls.count > 0) {
                MAImageViewerController *viewer = [[MAImageViewerController alloc] initWithImageURLs:urls initialIndex:index];
                [self presentViewController:viewer animated:YES completion:nil];
            }
            break;
        }
    }
}

- (void)handleLinkTapped:(NSNotification *)notif {
    if (!self.view.window) return;
    NSURL *url = notif.userInfo[@"url"];
    if (!url) return;

    MAWebViewController *webVC = [[MAWebViewController alloc] initWithURL:url];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:webVC];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)handleHashtagTapped:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *tag = notif.userInfo[@"tag"];
    if (!tag.length) return;

    MATimelineViewController *tagTimeline = [[MATimelineViewController alloc] initWithTimelineType:[NSString stringWithFormat:@"tag/%@", tag]];
    tagTimeline.title = [@"#" stringByAppendingString:tag];
    [self.navigationController pushViewController:tagTimeline animated:YES];
}

- (void)handleMentionTapped:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *acct = notif.userInfo[@"acct"];
    if (!acct.length) return;

    [[MAAPIClient sharedClient] lookupAccountWithAcct:acct completion:^(MAAccount *account, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.view.window) return;
            if (account) {
                MAProfileViewController *profile = [[MAProfileViewController alloc] initWithAccountID:account.accountID];
                [self.navigationController pushViewController:profile animated:YES];
            }
        });
    }];
}

#pragma mark - Data Loading

- (void)loadInitial {
    _maxID = nil;
    _hasMore = YES;
    [_loadingView showWithMessage:@"Loading..."];

    [[MAAPIClient sharedClient] fetchFavouritesWithMaxID:nil
                                              completion:^(NSArray *statuses, NSError *error) {
        [self->_loadingView hide];
        [self.refreshControl endRefreshing];

        if (error) {
            [self showError:error];
            return;
        }

        self->_statuses = [statuses mutableCopy];
        if (statuses.count > 0) {
            MAStatus *last = statuses.lastObject;
            self->_maxID = last.statusID;
        }
        self->_hasMore = statuses.count >= 20;
        [self.tableView reloadData];
        [self updateEmptyState];
    }];
}

- (void)refresh {
    [[MAAPIClient sharedClient] fetchFavouritesWithMaxID:nil
                                              completion:^(NSArray *statuses, NSError *error) {
        [self.refreshControl endRefreshing];

        if (error || statuses.count == 0) return;

        self->_statuses = [statuses mutableCopy];
        if (statuses.count > 0) {
            MAStatus *last = statuses.lastObject;
            self->_maxID = last.statusID;
        }
        self->_hasMore = statuses.count >= 20;
        [self.tableView reloadData];
        [self updateEmptyState];
    }];
}

- (void)loadMore {
    if (_isLoading || !_hasMore) return;
    _isLoading = YES;

    [[MAAPIClient sharedClient] fetchFavouritesWithMaxID:_maxID
                                              completion:^(NSArray *statuses, NSError *error) {
        self->_isLoading = NO;

        if (error || statuses.count == 0) {
            self->_hasMore = NO;
            return;
        }

        NSUInteger startIndex = self->_statuses.count;
        [self->_statuses addObjectsFromArray:statuses];

        if (statuses.count > 0) {
            MAStatus *last = statuses.lastObject;
            self->_maxID = last.statusID;
        }
        self->_hasMore = statuses.count >= 20;

        NSMutableArray *indexPaths = [NSMutableArray array];
        for (NSUInteger i = startIndex; i < self->_statuses.count; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }];
}

#pragma mark - Helpers

- (NSString *)stripHTML:(NSString *)html {
    if (!html) return @"";
    NSMutableString *result = [NSMutableString string];
    NSScanner *scanner = [NSScanner scannerWithString:html];
    while (![scanner isAtEnd]) {
        NSString *text = nil;
        [scanner scanUpToString:@"<" intoString:&text];
        if (text) [result appendString:text];
        [scanner scanUpToString:@">" intoString:NULL];
        [scanner scanString:@">" intoString:NULL];
    }
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)showError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self loadInitial];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _statuses.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MAStatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StatusCell" forIndexPath:indexPath];
    MAStatus *status = _statuses[indexPath.row];
    [cell configureWithStatus:status];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (NSInteger)_statuses.count - 5) {
        [self loadMore];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MAStatus *status = _statuses[indexPath.row];
    MAThreadViewController *thread = [[MAThreadViewController alloc] initWithStatusID:status.statusID];
    [self.navigationController pushViewController:thread animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

@end
