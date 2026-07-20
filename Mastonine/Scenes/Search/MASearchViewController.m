#import "MASearchViewController.h"
#import "MAAPIClient.h"
#import "MAAccount.h"
#import "MAStatus.h"
#import "MATheme.h"
#import "MAAccountTableViewCell.h"
#import "MAStatusTableViewCell.h"
#import "MAProfileViewController.h"
#import "MAThreadViewController.h"
#import "MATimelineViewController.h"

@implementation MASearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Explore";
    self.view.backgroundColor = [MATheme backgroundColor];

    _searchBar = [[UISearchBar alloc] init];
    _searchBar.delegate = self;
    _searchBar.placeholder = @"Search people, toots, hashtags...";
    _searchBar.barStyle = UIBarStyleDefault;
    _searchBar.searchBarStyle = UISearchBarStyleMinimal;
    _searchBar.keyboardAppearance = [MATheme isDarkMode] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    _searchBar.barTintColor = [MATheme backgroundColor];
    _searchBar.backgroundColor = [MATheme backgroundColor];
    _searchBar.translucent = NO;
    _searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    UITextField *searchField = [_searchBar valueForKey:@"searchField"];
    if (searchField) {
        searchField.textColor = [MATheme textColor];
        searchField.font = [MATheme fontWithSize:15];
    }
    [self.view addSubview:_searchBar];

    _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Accounts", @"Posts", @"Hashtags", @"News", @"For You"]];
    _segmentedControl.selectedSegmentIndex = 0;
    _segmentedControl.tintColor = [MATheme primaryColor];
    _segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    [_segmentedControl addTarget:self action:@selector(segmentChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_segmentedControl];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.backgroundColor = [MATheme backgroundColor];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 80;
    [_tableView registerClass:[MAAccountTableViewCell class] forCellReuseIdentifier:@"AccountCell"];
    [_tableView registerClass:[MAStatusTableViewCell class] forCellReuseIdentifier:@"StatusCell"];
    [self.view addSubview:_tableView];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _spinner.translatesAutoresizingMaskIntoConstraints = NO;
    _spinner.color = [MATheme primaryColor];
    _spinner.hidesWhenStopped = YES;
    [self.view addSubview:_spinner];

    [NSLayoutConstraint activateConstraints:@[
        [_searchBar.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:64],
        [_searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [_segmentedControl.topAnchor constraintEqualToAnchor:_searchBar.bottomAnchor constant:8],
        [_segmentedControl.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_segmentedControl.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [_tableView.topAnchor constraintEqualToAnchor:_segmentedControl.bottomAnchor constant:8],
        [_tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [_spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_spinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];

    _accountResults = @[];
    _statusResults = @[];
    _tagResults = @[];
    _trendingStatuses = @[];
    _suggestedAccounts = @[];

    [self loadExploreData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSInteger idx = _segmentedControl.selectedSegmentIndex;
    if (idx == 3 && _trendingStatuses.count == 0) {
        [self loadTrendingStatuses];
    } else if (idx == 4 && _suggestedAccounts.count == 0) {
        [self loadSuggestedAccounts];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)segmentChanged {
    NSInteger idx = _segmentedControl.selectedSegmentIndex;
    if (idx == 3 && _trendingStatuses.count == 0) {
        [self loadTrendingStatuses];
    } else if (idx == 4 && _suggestedAccounts.count == 0) {
        [self loadSuggestedAccounts];
    }
    [_tableView reloadData];
}

#pragma mark - Data Loading

- (void)loadExploreData {
    [self loadTrendingStatuses];
}

- (void)loadTrendingStatuses {
    [_spinner startAnimating];
    [[MAAPIClient sharedClient] fetchTrendingStatusesWithCompletion:^(NSArray *statuses, NSError *error) {
        [self->_spinner stopAnimating];
        if (!error && statuses) {
            self->_trendingStatuses = statuses;
            if (self->_segmentedControl.selectedSegmentIndex == 3) {
                [self->_tableView reloadData];
            }
        }
    }];
}

- (void)loadSuggestedAccounts {
    [_spinner startAnimating];
    [[MAAPIClient sharedClient] fetchSuggestedAccountsWithCompletion:^(NSArray *accounts, NSError *error) {
        [self->_spinner stopAnimating];
        if (!error && accounts) {
            self->_suggestedAccounts = accounts;
            if (self->_segmentedControl.selectedSegmentIndex == 4) {
                [self->_tableView reloadData];
            }
        }
    }];
}

- (void)performSearch:(NSString *)query {
    if (query.length == 0) return;

    [_spinner startAnimating];
    [[MAAPIClient sharedClient] searchQuery:query completion:^(NSDictionary *results, NSError *error) {
        [self->_spinner stopAnimating];
        if (error || !results) return;

        self->_accountResults = results[@"accounts"] ?: @[];
        self->_statusResults = results[@"statuses"] ?: @[];
        self->_tagResults = results[@"hashtags"] ?: @[];
        [self->_tableView reloadData];
    }];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self performSearch:searchBar.text];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (_segmentedControl.selectedSegmentIndex) {
        case 0: return _accountResults.count;
        case 1: return _statusResults.count;
        case 2: return _tagResults.count;
        case 3: return _trendingStatuses.count;
        case 4: return _suggestedAccounts.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (_segmentedControl.selectedSegmentIndex) {
        case 0: {
            MAAccountTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AccountCell" forIndexPath:indexPath];
            NSDictionary *dict = _accountResults[indexPath.row];
            MAAccount *account = [MAAccount accountFromDictionary:dict];
            [cell configureWithAccount:account];
            return cell;
        }
        case 1: {
            MAStatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StatusCell" forIndexPath:indexPath];
            NSDictionary *dict = _statusResults[indexPath.row];
            MAStatus *status = [MAStatus statusFromDictionary:dict];
            [cell configureWithStatus:status];
            return cell;
        }
        case 2: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TagCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TagCell"];
                cell.backgroundColor = [MATheme cardColor];
                cell.textLabel.textColor = [MATheme primaryColor];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            NSDictionary *tag = _tagResults[indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat:@"#%@", tag[@"name"] ?: @""];
            return cell;
        }
        case 3: {
            MAStatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StatusCell" forIndexPath:indexPath];
            MAStatus *status = _trendingStatuses[indexPath.row];
            [cell configureWithStatus:status];
            return cell;
        }
        case 4: {
            MAAccountTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AccountCell" forIndexPath:indexPath];
            id item = _suggestedAccounts[indexPath.row];
            MAAccount *account = [item isKindOfClass:[MAAccount class]] ? item : [MAAccount accountFromDictionary:item];
            [cell configureWithAccount:account];
            return cell;
        }
    }
    return [[UITableViewCell alloc] init];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (_segmentedControl.selectedSegmentIndex) {
        case 0: {
            NSDictionary *dict = _accountResults[indexPath.row];
            MAProfileViewController *profile = [[MAProfileViewController alloc] initWithAccountID:[dict[@"id"] description]];
            [self.navigationController pushViewController:profile animated:YES];
            break;
        }
        case 1: {
            NSDictionary *dict = _statusResults[indexPath.row];
            MAThreadViewController *thread = [[MAThreadViewController alloc] initWithStatusID:[dict[@"id"] description]];
            [self.navigationController pushViewController:thread animated:YES];
            break;
        }
        case 2: {
            NSDictionary *tag = _tagResults[indexPath.row];
            NSString *tagName = tag[@"name"] ?: @"";
            if (tagName.length > 0) {
                MATimelineViewController *tagTimeline = [[MATimelineViewController alloc] initWithTimelineType:[NSString stringWithFormat:@"tag/%@", tagName]];
                [self.navigationController pushViewController:tagTimeline animated:YES];
            }
            break;
        }
        case 3: {
            MAStatus *status = _trendingStatuses[indexPath.row];
            MAThreadViewController *thread = [[MAThreadViewController alloc] initWithStatusID:status.statusID];
            [self.navigationController pushViewController:thread animated:YES];
            break;
        }
        case 4: {
            id item = _suggestedAccounts[indexPath.row];
            NSString *accountID = nil;
            if ([item isKindOfClass:[MAAccount class]]) {
                accountID = ((MAAccount *)item).accountID;
            } else if ([item isKindOfClass:[NSDictionary class]]) {
                accountID = [((NSDictionary *)item)[@"id"] description];
            }
            if (accountID) {
                MAProfileViewController *profile = [[MAProfileViewController alloc] initWithAccountID:accountID];
                [self.navigationController pushViewController:profile animated:YES];
            }
            break;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

@end
