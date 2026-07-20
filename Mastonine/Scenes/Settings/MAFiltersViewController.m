#import "MAFiltersViewController.h"
#import "MAFilterManager.h"
#import "MATheme.h"

@implementation MAFiltersViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Content Filters";
    self.view.backgroundColor = [MATheme backgroundColor];
    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.tableFooterView = [[UIView alloc] init];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(addFilterTapped)];

    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.tintColor = [MATheme primaryColor];
    [refresh addTarget:self action:@selector(refreshFilters) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;

    [self loadFilters];
}

- (void)loadFilters {
    [self.refreshControl beginRefreshing];
    [[MAFilterManager sharedManager] loadFiltersWithCompletion:^{
        [self.refreshControl endRefreshing];
        [self.tableView reloadData];
    }];
}

- (void)refreshFilters {
    [self loadFilters];
}

#pragma mark - Add Filter

- (void)addFilterTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Filter"
                                                                  message:@"Enter a phrase to filter"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Filter phrase";
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *phrase = alert.textFields.firstObject.text;
        if (phrase.length == 0) return;

        NSArray *contexts = @[@"home", @"notifications", @"public", @"thread"];
        [[MAFilterManager sharedManager] addFilterWithPhrase:phrase
                                                    context:contexts
                                           expiresInSeconds:0
                                                 completion:^(NSError *error) {
            if (error) {
                UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                    message:[NSString stringWithFormat:@"Failed to add filter: %@", error.localizedDescription]
                                                                             preferredStyle:UIAlertControllerStyleAlert];
                [errorAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:errorAlert animated:YES completion:nil];
                return;
            }
            [self.tableView reloadData];
        }];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *filters = [[MAFilterManager sharedManager] activeFilters];
    if (filters.count == 0) {
        return 1;
    }
    return filters.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Active Filters";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSArray *filters = [[MAFilterManager sharedManager] activeFilters];
    if (filters.count == 0) {
        return @"No content filters are set. Tap \"Add\" to create one.";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"FilterCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.backgroundColor = [MATheme cardColor];
        cell.textLabel.textColor = [MATheme textColor];
        cell.detailTextLabel.textColor = [MATheme secondaryTextColor];

        UIView *bgView = [[UIView alloc] init];
        bgView.backgroundColor = [MATheme primaryDarkColor];
        cell.selectedBackgroundView = bgView;
    }

    NSArray *filters = [[MAFilterManager sharedManager] activeFilters];

    if (filters.count == 0) {
        cell.textLabel.text = @"No filters";
        cell.textLabel.textColor = [MATheme secondaryTextColor];
        cell.detailTextLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }

    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryNone;

    NSDictionary *filter = filters[indexPath.row];
    cell.textLabel.text = filter[@"phrase"] ?: @"";
    cell.textLabel.textColor = [MATheme textColor];

    NSArray *contexts = filter[@"context"];
    if ([contexts isKindOfClass:[NSArray class]] && contexts.count > 0) {
        cell.detailTextLabel.text = [contexts componentsJoinedByString:@", "];
    } else {
        cell.detailTextLabel.text = @"";
    }
    cell.detailTextLabel.textColor = [MATheme secondaryTextColor];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *filters = [[MAFilterManager sharedManager] activeFilters];
    return filters.count > 0;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;

    NSArray *filters = [[MAFilterManager sharedManager] activeFilters];
    NSDictionary *filter = filters[indexPath.row];
    NSString *filterID = filter[@"id"];
    if (!filterID) return;

    UIAlertController *confirm = [UIAlertController alertControllerWithTitle:@"Delete Filter"
                                                                    message:[NSString stringWithFormat:@"Remove filter \"%@\"?", filter[@"phrase"]]
                                                             preferredStyle:UIAlertControllerStyleAlert];
    [confirm addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [confirm addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[MAFilterManager sharedManager] deleteFilterWithID:filterID completion:^(NSError *error) {
            if (error) {
                UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                    message:[NSString stringWithFormat:@"Failed to delete filter: %@", error.localizedDescription]
                                                                             preferredStyle:UIAlertControllerStyleAlert];
                [errorAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:errorAlert animated:YES completion:nil];
                return;
            }
            [self.tableView reloadData];
        }];
    }]];
    [self presentViewController:confirm animated:YES completion:nil];
}

@end
