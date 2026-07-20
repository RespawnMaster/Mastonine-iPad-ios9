#import "MAInstanceSelectionViewController.h"
#import "MATheme.h"

@interface MAInstanceSelectionViewController ()

@property (nonatomic, strong) NSArray *instances;
@property (nonatomic, strong) NSArray *filteredInstances;

@end

@implementation MAInstanceSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Choose Instance";
    self.view.backgroundColor = [MATheme backgroundColor];

    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.separatorColor = [MATheme separatorColor];
    self.tableView.tableFooterView = [[UIView alloc] init];

    _instances = @[
        @{@"name": @"mastodon.social", @"description": @"The flagship Mastodon instance"},
        @{@"name": @"mastodon.online", @"description": @"A welcoming Mastodon community"},
        @{@"name": @"fosstodon.org", @"description": @"FLOSS & open source community"},
        @{@"name": @"hachyderm.io", @"description": @"A safe space for the tech community"},
        @{@"name": @"mastodon.art", @"description": @"Art and creative community"},
        @{@"name": @"techhub.social", @"description": @"Technology enthusiasts"},
        @{@"name": @"birds.town", @"description": @"For bird lovers"},
        @{@"name": @"norden.social", @"description": @"Nordic community"},
        @{@"name": @"social.coop", @"description": @"Co-operatively organized"},
        @{@"name": @"InfoSec.Exchange", @"description": @"Information security community"},
    ];
    _filteredInstances = _instances;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancelTapped)];

    UISearchBar *searchBar = [[UISearchBar alloc] init];
    searchBar.placeholder = @"Search instances...";
    searchBar.barStyle = UIBarStyleDefault;
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.delegate = (id)self;
    searchBar.backgroundColor = [MATheme backgroundColor];
    searchBar.keyboardAppearance = [MATheme isDarkMode] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    self.tableView.tableHeaderView = searchBar;
}

- (void)cancelTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        _filteredInstances = _instances;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR description CONTAINS[cd] %@", searchText, searchText];
        _filteredInstances = [_instances filteredArrayUsingPredicate:predicate];
    }
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *text = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length > 0) {
        if ([self.delegate respondsToSelector:@selector(instanceSelectionDidSelectInstance:)]) {
            [self.delegate instanceSelectionDidSelectInstance:text];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _filteredInstances.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InstanceCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"InstanceCell"];
        cell.backgroundColor = [MATheme cardColor];
        cell.textLabel.textColor = [MATheme textColor];
        cell.detailTextLabel.textColor = [MATheme secondaryTextColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        UIView *bgView = [[UIView alloc] init];
        bgView.backgroundColor = [MATheme primaryDarkColor];
        cell.selectedBackgroundView = bgView;
    }

    NSDictionary *instance = _filteredInstances[indexPath.row];
    cell.textLabel.text = instance[@"name"];
    cell.detailTextLabel.text = instance[@"description"];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *instance = _filteredInstances[indexPath.row];
    if ([self.delegate respondsToSelector:@selector(instanceSelectionDidSelectInstance:)]) {
        [self.delegate instanceSelectionDidSelectInstance:instance[@"name"]];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}

@end
