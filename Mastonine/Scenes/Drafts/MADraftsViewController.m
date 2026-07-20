#import "MADraftsViewController.h"
#import "MADraftManager.h"
#import "MAComposeViewController.h"
#import "MATheme.h"
#import "MAEmptyStateView.h"

@interface MADraftsViewController ()

@property (nonatomic, strong) NSArray *drafts;
@property (nonatomic, strong) MAEmptyStateView *emptyView;

@end

@implementation MADraftsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Drafts";

    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.separatorColor = [MATheme separatorColor];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DraftCell"];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete All"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(deleteAllTapped)];

    _emptyView = [[MAEmptyStateView alloc] initWithIcon:@"~" title:@"No Drafts" subtitle:@"Drafts you save will appear here"];
    _emptyView.frame = self.view.bounds;
    _emptyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _emptyView.hidden = YES;
    [self.view addSubview:_emptyView];

    UIRefreshControl *rc = [[UIRefreshControl alloc] init];
    rc.tintColor = [MATheme primaryColor];
    [rc addTarget:self action:@selector(refreshDrafts) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = rc;

    [self loadDrafts];
}

- (void)refreshDrafts {
    [self loadDrafts];
    [self.refreshControl endRefreshing];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadDrafts];
}

- (void)loadDrafts {
    self.drafts = [[MADraftManager sharedManager] loadAllDrafts];
    [self.tableView reloadData];
    self.emptyView.hidden = (self.drafts.count > 0);
}

#pragma mark - Actions

- (void)deleteAllTapped {
    if (self.drafts.count == 0) return;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete All Drafts"
                                                                   message:@"Are you sure you want to delete all drafts? This cannot be undone."
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Delete All" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[MADraftManager sharedManager] deleteAllDrafts];
        [self loadDrafts];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openComposeWithDraft:(NSDictionary *)draft {
    MAComposeViewController *composeVC = [[MAComposeViewController alloc] init];
    composeVC.replyToStatusID = draft[@"replyToStatusID"];
    composeVC.replyToUsername = draft[@"replyToUsername"];
    composeVC.visibility = draft[@"visibility"];
    composeVC.draftText = draft[@"text"];
    composeVC.draftID = draft[@"draftID"];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:composeVC];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.drafts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DraftCell" forIndexPath:indexPath];

    NSDictionary *draft = self.drafts[indexPath.row];

    cell.textLabel.text = draft[@"text"];
    cell.textLabel.numberOfLines = 3;
    cell.textLabel.textColor = [MATheme textColor];

    NSTimeInterval timestamp = [draft[@"timestamp"] doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    cell.detailTextLabel.text = [formatter stringFromDate:date];
    cell.detailTextLabel.textColor = [MATheme secondaryTextColor];

    cell.backgroundColor = [MATheme cardColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *draft = self.drafts[indexPath.row];
        [[MADraftManager sharedManager] deleteDraftWithID:draft[@"draftID"]];

        NSMutableArray *mutableDrafts = [self.drafts mutableCopy];
        [mutableDrafts removeObjectAtIndex:indexPath.row];
        self.drafts = [mutableDrafts copy];

        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *draft = self.drafts[indexPath.row];
    NSString *draftID = draft[@"draftID"];

    [self openComposeWithDraft:draft];
    [[MADraftManager sharedManager] deleteDraftWithID:draftID];

    NSMutableArray *mutableDrafts = [self.drafts mutableCopy];
    [mutableDrafts removeObjectAtIndex:indexPath.row];
    self.drafts = [mutableDrafts copy];

    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
