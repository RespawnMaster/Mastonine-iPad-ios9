#import "MAExploreViewController.h"
#import "MAStatusTableViewCell.h"
#import "MAAccountTableViewCell.h"
#import "MAAPIClient.h"
#import "MAStatus.h"
#import "MAAccount.h"
#import "MATheme.h"
#import "MALoadingView.h"
#import "MATimelineViewController.h"
#import "MAThreadViewController.h"
#import "MAProfileViewController.h"

@interface MAExploreViewController ()

@property (nonatomic, strong) MALoadingView *loadingView;

@end

@implementation MAExploreViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _trendingTags = @[];
        _suggestedAccounts = @[];
        _trendingStatuses = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Explore";
    self.view.backgroundColor = [MATheme backgroundColor];
    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 200;

    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }

    [self.tableView registerClass:[MAStatusTableViewCell class] forCellReuseIdentifier:@"StatusCell"];
    [self.tableView registerClass:[MAAccountTableViewCell class] forCellReuseIdentifier:@"AccountCell"];

    UIRefreshControl *rc = [[UIRefreshControl alloc] init];
    rc.tintColor = [MATheme primaryColor];
    [rc addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = rc;

    _loadingView = [[MALoadingView alloc] initWithFrame:self.view.bounds];
    _loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_loadingView];

    [self loadAll];
}

- (void)loadAll {
    [_loadingView showWithMessage:@"Loading..."];

    dispatch_group_t group = dispatch_group_create();
    __block NSError *firstError = nil;

    dispatch_group_enter(group);
    [[MAAPIClient sharedClient] fetchTrendingTagsWithCompletion:^(NSArray *tags, NSError *error) {
        if (error && !firstError) firstError = error;
        self->_trendingTags = tags ?: @[];
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[MAAPIClient sharedClient] fetchSuggestedAccountsWithCompletion:^(NSArray *accounts, NSError *error) {
        if (error && !firstError) firstError = error;
        self->_suggestedAccounts = accounts ?: @[];
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[MAAPIClient sharedClient] fetchTrendingStatusesWithCompletion:^(NSArray *statuses, NSError *error) {
        if (error && !firstError) firstError = error;
        self->_trendingStatuses = statuses ?: @[];
        dispatch_group_leave(group);
    }];

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self->_loadingView hide];
        [self.refreshControl endRefreshing];
        [self.tableView reloadData];
    });
}

- (void)refresh {
    _trendingTags = @[];
    _suggestedAccounts = @[];
    _trendingStatuses = @[];
    [self loadAll];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return _trendingTags.count;
        case 1: return _suggestedAccounts.count;
        case 2: return _trendingStatuses.count;
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"Tags";
        case 1: return @"Suggested";
        case 2: return @"Posts";
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TagCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TagCell"];
            cell.backgroundColor = [MATheme cardColor];
            cell.textLabel.font = [MATheme fontWithSize:16];
            cell.textLabel.textColor = [MATheme primaryColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        NSDictionary *tag = _trendingTags[indexPath.row];
        NSString *name = tag[@"name"] ?: @"";
        cell.textLabel.text = [NSString stringWithFormat:@"#%@", name];
        return cell;
    } else if (indexPath.section == 1) {
        MAAccountTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AccountCell" forIndexPath:indexPath];
        MAAccount *account = _suggestedAccounts[indexPath.row];
        [cell configureWithAccount:account];
        return cell;
    } else {
        MAStatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StatusCell" forIndexPath:indexPath];
        MAStatus *status = _trendingStatuses[indexPath.row];
        [cell configureWithStatus:status];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSDictionary *tag = _trendingTags[indexPath.row];
        NSString *name = tag[@"name"] ?: @"";
        MATimelineViewController *timeline = [[MATimelineViewController alloc] initWithTimelineType:[NSString stringWithFormat:@"tag/%@", name]];
        [self.navigationController pushViewController:timeline animated:YES];
    } else if (indexPath.section == 1) {
        MAAccount *account = _suggestedAccounts[indexPath.row];
        MAProfileViewController *profile = [[MAProfileViewController alloc] initWithAccountID:account.accountID];
        [self.navigationController pushViewController:profile animated:YES];
    } else {
        MAStatus *status = _trendingStatuses[indexPath.row];
        MAThreadViewController *thread = [[MAThreadViewController alloc] initWithStatusID:status.statusID];
        [self.navigationController pushViewController:thread animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        return UITableViewAutomaticDimension;
    }
    return UITableViewAutomaticDimension;
}

@end
