#import "MAListTimelineViewController.h"
#import "MAStatusTableViewCell.h"
#import "MAAPIClient.h"
#import "MAStatus.h"
#import "MAMediaAttachment.h"
#import "MALoadingView.h"
#import "MATheme.h"
#import "MAThreadViewController.h"
#import "MAProfileViewController.h"
#import "MAComposeViewController.h"
#import "MAImageViewerController.h"
#import "MAAccount.h"
#import "MAListMembersViewController.h"

@interface MAListTimelineViewController ()

@property (nonatomic, strong) MALoadingView *loadingView;

@end

@implementation MAListTimelineViewController

- (instancetype)initWithListID:(NSString *)listID title:(NSString *)title {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _listID = listID;
        _statuses = [NSMutableArray array];
        _hasMore = YES;
        self.title = title ?: @"List";
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    return [self initWithListID:nil title:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

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

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Manage"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(manageTapped)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusUpdated:) name:@"MAStatusUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAvatarTapped:) name:@"MAAvatarTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMediaTapped:) name:@"MAMediaTapped" object:nil];

    [self loadInitial];
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

#pragma mark - Data Loading

- (void)loadInitial {
    _maxID = nil;
    _hasMore = YES;
    [_loadingView showWithMessage:@"Loading..."];

    [[MAAPIClient sharedClient] fetchListTimeline:_listID maxID:nil completion:^(NSArray *statuses, NSError *error) {
        [self->_loadingView hide];
        [self.refreshControl endRefreshing];

        if (error) return;

        self->_statuses = [statuses mutableCopy];
        if (statuses.count > 0) {
            MAStatus *last = statuses.lastObject;
            self->_maxID = last.statusID;
        }
        self->_hasMore = statuses.count >= 20;
        [self.tableView reloadData];
    }];
}

- (void)refresh {
    NSString *sinceID = nil;
    if (self->_statuses.count > 0) {
        sinceID = [self->_statuses.firstObject statusID];
    }

    [[MAAPIClient sharedClient] fetchListTimeline:_listID maxID:nil completion:^(NSArray *statuses, NSError *error) {
        [self.refreshControl endRefreshing];
        if (error || statuses.count == 0) return;

        NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
        for (NSUInteger i = 0; i < statuses.count; i++) {
            [indexes addIndex:i];
        }
        [self->_statuses insertObjects:statuses atIndexes:indexes];
        [self.tableView reloadData];
    }];
}

- (void)loadMore {
    if (_isLoading || !_hasMore) return;
    _isLoading = YES;

    [[MAAPIClient sharedClient] fetchListTimeline:_listID maxID:_maxID completion:^(NSArray *statuses, NSError *error) {
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

- (void)manageTapped {
    MAListMembersViewController *members = [[MAListMembersViewController alloc] initWithListID:_listID];
    [self.navigationController pushViewController:members animated:YES];
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
