#import "MAManageHashtagsViewController.h"
#import "MAAPIClient.h"
#import "MATheme.h"
#import "MALoadingView.h"

@interface MAManageHashtagsViewController ()

@property (nonatomic, strong) MALoadingView *loadingView;
@property (nonatomic, strong) UIBarButtonItem *editButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *unfollowButton;

@end

@implementation MAManageHashtagsViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _hashtags = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Manage Hashtags";
    self.view.backgroundColor = [MATheme backgroundColor];
    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.navigationController.toolbarHidden = YES;

    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }

    _editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                  style:UIBarButtonItemStylePlain
                                                 target:self
                                                 action:@selector(editTapped)];
    _doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                  style:UIBarButtonItemStyleDone
                                                 target:self
                                                 action:@selector(editTapped)];
    _unfollowButton = [[UIBarButtonItem alloc] initWithTitle:@"Unfollow"
                                                      style:UIBarButtonItemStyleDone
                                                     target:self
                                                     action:@selector(unfollowSelected)];
    _unfollowButton.tintColor = [MATheme dangerColor];

    self.navigationItem.rightBarButtonItem = _editButton;

    UIRefreshControl *rc = [[UIRefreshControl alloc] init];
    rc.tintColor = [MATheme primaryColor];
    [rc addTarget:self action:@selector(loadHashtags) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = rc;

    _loadingView = [[MALoadingView alloc] initWithFrame:self.view.bounds];
    _loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_loadingView];

    [self loadHashtags];
}

- (void)loadHashtags {
    [_loadingView showWithMessage:@"Loading..."];

    [[MAAPIClient sharedClient] fetchFollowedHashtagsWithCompletion:^(NSArray *tags, NSError *error) {
        [self->_loadingView hide];
        [self.refreshControl endRefreshing];

        if (error) return;

        self.hashtags = [tags mutableCopy];
        [self.tableView reloadData];
    }];
}

- (void)editTapped {
    BOOL editing = !self.tableView.isEditing;
    [self.tableView setEditing:editing animated:YES];

    if (editing) {
        self.navigationItem.rightBarButtonItems = @[_unfollowButton, _doneButton];
    } else {
        self.navigationItem.rightBarButtonItems = @[_editButton];
    }
    [self updateUnfollowButton];
}

- (void)updateUnfollowButton {
    NSInteger count = [self.tableView indexPathsForSelectedRows].count;
    _unfollowButton.enabled = (count > 0);
    _unfollowButton.title = count > 0 ? [NSString stringWithFormat:@"Unfollow (%ld)", (long)count] : @"Unfollow";
}

- (void)unfollowSelected {
    NSArray *selectedPaths = [self.tableView indexPathsForSelectedRows];
    if (selectedPaths.count == 0) return;

    NSMutableArray *names = [NSMutableArray array];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (NSIndexPath *path in selectedPaths) {
        [indexes addIndex:path.row];
        NSDictionary *tag = self.hashtags[path.row];
        if (tag[@"name"]) [names addObject:tag[@"name"]];
    }

    __block NSInteger remaining = names.count;

    for (NSString *name in names) {
        [[MAAPIClient sharedClient] unfollowHashtag:name completion:^(NSError *error) {
            remaining--;
            if (remaining == 0) {
                [self.hashtags removeObjectsAtIndexes:indexes];
                [self.tableView reloadData];
                [self updateUnfollowButton];
            }
        }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.hashtags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HashtagCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"HashtagCell"];
        cell.textLabel.font = [MATheme fontWithSize:16];
        cell.textLabel.textColor = [MATheme textColor];
        cell.backgroundColor = [MATheme cardColor];
    }

    NSDictionary *tag = self.hashtags[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"#%@", tag[@"name"] ?: @""];
    cell.textLabel.backgroundColor = [UIColor clearColor];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 1;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        [self updateUnfollowButton];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        [self updateUnfollowButton];
    }
}

@end
