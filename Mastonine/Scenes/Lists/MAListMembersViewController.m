#import "MAListMembersViewController.h"
#import "MAAccountTableViewCell.h"
#import "MAAccount.h"
#import "MAAPIClient.h"
#import "MATheme.h"
#import "MALoadingView.h"
#import "MAProfileViewController.h"
#import "MASearchViewController.h"

@interface MAListMembersViewController ()

@property (nonatomic, strong) MALoadingView *loadingView;

@end

@implementation MAListMembersViewController

- (instancetype)initWithListID:(NSString *)listID {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _listID = listID;
        _accounts = [NSMutableArray array];
        _hasMore = YES;
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    return [self initWithListID:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"List Members";
    self.view.backgroundColor = [MATheme backgroundColor];
    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;

    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }

    [self.tableView registerClass:[MAAccountTableViewCell class] forCellReuseIdentifier:@"AccountCell"];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addMemberTapped)];

    UIRefreshControl *rc = [[UIRefreshControl alloc] init];
    rc.tintColor = [MATheme primaryColor];
    [rc addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = rc;

    _loadingView = [[MALoadingView alloc] initWithFrame:self.view.bounds];
    _loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_loadingView];

    [self loadAccounts];
}

- (void)loadAccounts {
    [_loadingView showWithMessage:@"Loading..."];

    [[MAAPIClient sharedClient] fetchListAccounts:_listID maxID:_maxID completion:^(NSArray *accounts, NSError *error) {
        [self->_loadingView hide];
        [self.refreshControl endRefreshing];

        if (error) return;

        if (self->_maxID) {
            [self->_accounts addObjectsFromArray:accounts];
        } else {
            self->_accounts = [accounts mutableCopy];
        }

        if (accounts.count > 0) {
            MAAccount *last = accounts.lastObject;
            self->_maxID = last.accountID;
        }
        self->_hasMore = accounts.count >= 20;
        [self.tableView reloadData];
    }];
}

- (void)refresh {
    _maxID = nil;
    _hasMore = YES;
    [self loadAccounts];
}

- (void)addMemberTapped {
    MASearchViewController *search = [[MASearchViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:search];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)removeAccountAtIndexPath:(NSIndexPath *)indexPath {
    MAAccount *account = _accounts[indexPath.row];

    [[MAAPIClient sharedClient] removeAccountsFromList:_listID accountIDs:@[account.accountID] completion:^(NSError *error) {
        if (!error) {
            [self->_accounts removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _accounts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MAAccountTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AccountCell" forIndexPath:indexPath];
    MAAccount *account = _accounts[indexPath.row];
    [cell configureWithAccount:account];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self removeAccountAtIndexPath:indexPath];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Remove";
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MAAccount *account = _accounts[indexPath.row];
    MAProfileViewController *profile = [[MAProfileViewController alloc] initWithAccountID:account.accountID];
    [self.navigationController pushViewController:profile animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (NSInteger)_accounts.count - 5 && _hasMore) {
        [self loadAccounts];
    }
}

@end
