#import "MAAccountListViewController.h"
#import "MAAccountTableViewCell.h"
#import "MAAPIClient.h"
#import "MAAccount.h"
#import "MATheme.h"
#import "MAProfileViewController.h"

@interface MAAccountListViewController ()
@property (nonatomic, strong) NSMutableArray *accounts;
@property (nonatomic, copy) NSString *maxID;
@property (nonatomic, assign) BOOL isLoading;
@end

@implementation MAAccountListViewController

- (instancetype)initWithAccountID:(NSString *)accountID followers:(BOOL)followers {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _accountID = accountID;
        _mode = followers ? MAAccountListModeFollowers : MAAccountListModeFollowing;
        _accounts = [NSMutableArray array];
        _listTitle = followers ? @"Followers" : @"Following";
    }
    return self;
}

- (instancetype)initWithStatusID:(NSString *)statusID rebloggedBy:(BOOL)reblogged {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _statusID = statusID;
        _mode = reblogged ? MAAccountListModeRebloggedBy : MAAccountListModeFavouritedBy;
        _accounts = [NSMutableArray array];
        _listTitle = reblogged ? @"Reblogged By" : @"Favourited By";
    }
    return self;
}

- (instancetype)initWithBlocked {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _mode = MAAccountListModeBlocked;
        _accounts = [NSMutableArray array];
        _listTitle = @"Blocked Users";
    }
    return self;
}

- (instancetype)initWithMuted {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _mode = MAAccountListModeMuted;
        _accounts = [NSMutableArray array];
        _listTitle = @"Muted Users";
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    return [self initWithAccountID:nil followers:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = _listTitle;
    self.view.backgroundColor = [MATheme backgroundColor];
    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[MAAccountTableViewCell class] forCellReuseIdentifier:@"AccountCell"];
    [self loadAccounts];
}

- (void)loadAccounts {
    if (_isLoading) return;
    _isLoading = YES;

    void (^handler)(NSArray *, NSError *) = ^(NSArray *accounts, NSError *error) {
        self.isLoading = NO;
        if (error || accounts.count == 0) return;

        if (self.maxID) {
            [self.accounts addObjectsFromArray:accounts];
        } else {
            self.accounts = [accounts mutableCopy];
        }

        if (accounts.count > 0) {
            MAAccount *last = accounts.lastObject;
            self.maxID = last.accountID;
        }

        [self.tableView reloadData];
    };

    switch (_mode) {
        case MAAccountListModeFollowers:
            [[MAAPIClient sharedClient] fetchFollowers:_accountID maxID:_maxID completion:handler];
            break;
        case MAAccountListModeFollowing:
            [[MAAPIClient sharedClient] fetchFollowing:_accountID maxID:_maxID completion:handler];
            break;
        case MAAccountListModeRebloggedBy:
            [[MAAPIClient sharedClient] fetchRebloggedByStatusID:_statusID maxID:_maxID completion:handler];
            break;
        case MAAccountListModeFavouritedBy:
            [[MAAPIClient sharedClient] fetchFavouritedByStatusID:_statusID maxID:_maxID completion:handler];
            break;
        case MAAccountListModeBlocked:
            [[MAAPIClient sharedClient] fetchBlockedAccountsWithMaxID:_maxID completion:handler];
            break;
        case MAAccountListModeMuted:
            [[MAAPIClient sharedClient] fetchMutedAccountsWithMaxID:_maxID completion:handler];
            break;
    }
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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (NSInteger)_accounts.count - 10) {
        [self loadAccounts];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MAAccount *account = _accounts[indexPath.row];
    MAProfileViewController *profile = [[MAProfileViewController alloc] initWithAccountID:account.accountID];
    [self.navigationController pushViewController:profile animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

@end
