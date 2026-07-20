#import "MABookmarksViewController.h"
#import "MAStatusTableViewCell.h"
#import "MAAPIClient.h"
#import "MAStatus.h"
#import "MATheme.h"
#import "MAThreadViewController.h"
#import "MAEmptyStateView.h"

@interface MABookmarksViewController ()

@property (nonatomic, strong) NSMutableArray *statuses;
@property (nonatomic, copy) NSString *maxID;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, strong) MAEmptyStateView *emptyView;

@end

@implementation MABookmarksViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _statuses = [NSMutableArray array];
        _hasMore = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Bookmarks";
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

    _emptyView = [[MAEmptyStateView alloc] initWithIcon:@"\u2764" title:@"No Bookmarks" subtitle:@"Posts you bookmark will appear here"];
    _emptyView.frame = self.view.bounds;
    _emptyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _emptyView.hidden = YES;
    [self.view addSubview:_emptyView];

    [self loadBookmarks];
}

- (void)updateEmptyState {
    self.emptyView.hidden = (_statuses.count > 0);
}

#pragma mark - Data Loading

- (void)loadBookmarks {
    [[MAAPIClient sharedClient] fetchBookmarksWithMaxID:_maxID completion:^(NSArray *statuses, NSError *error) {
        [self.refreshControl endRefreshing];

        if (error) return;

        if (self->_maxID) {
            [self->_statuses addObjectsFromArray:statuses];
        } else {
            self->_statuses = [statuses mutableCopy];
        }

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
    _maxID = nil;
    _hasMore = YES;
    [self loadBookmarks];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MAStatus *status = _statuses[indexPath.row];
    MAThreadViewController *thread = [[MAThreadViewController alloc] initWithStatusID:status.statusID];
    [self.navigationController pushViewController:thread animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 200;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (NSInteger)_statuses.count - 5 && _hasMore) {
        [self loadBookmarks];
    }
}

@end
