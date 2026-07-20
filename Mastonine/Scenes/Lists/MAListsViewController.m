#import "MAListsViewController.h"
#import "MAList.h"
#import "MAAPIClient.h"
#import "MATheme.h"
#import "MALoadingView.h"
#import "MAListTimelineViewController.h"
#import "MAEmptyStateView.h"

@interface MAListsViewController ()

@property (nonatomic, strong) MALoadingView *loadingView;
@property (nonatomic, strong) MAEmptyStateView *emptyView;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation MAListsViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _lists = [NSMutableArray array];
        _hasMore = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Lists";
    self.view.backgroundColor = [MATheme backgroundColor];
    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50;

    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addListTapped)];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                         target:self
                                                                                         action:@selector(editTapped)];

    self.editing = NO;

    UIRefreshControl *rc = [[UIRefreshControl alloc] init];
    rc.tintColor = [MATheme primaryColor];
    [rc addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = rc;

    _loadingView = [[MALoadingView alloc] initWithFrame:self.view.bounds];
    _loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_loadingView];

    _emptyView = [[MAEmptyStateView alloc] initWithIcon:@">" title:@"No Lists" subtitle:@"Create a list to group accounts together"];
    _emptyView.frame = self.view.bounds;
    _emptyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _emptyView.hidden = YES;
    [self.view addSubview:_emptyView];

    [self loadLists];
}

- (void)loadLists {
    if (_isLoading) return;
    _isLoading = YES;

    if (_maxID.length == 0) {
        [_loadingView showWithMessage:@"Loading..."];
    }

    [[MAAPIClient sharedClient] fetchListsMaxID:_maxID completion:^(NSArray *lists, NSError *error) {
        self->_isLoading = NO;
        [self->_loadingView hide];
        [self.refreshControl endRefreshing];

        if (error) return;

        if (self->_maxID.length == 0) {
            self->_lists = [lists mutableCopy];
        } else {
            [self->_lists addObjectsFromArray:lists];
        }

        if (lists.count > 0) {
            MAList *last = lists.lastObject;
            self->_maxID = last.listID;
        }
        self->_hasMore = lists.count >= 20;
        [self.tableView reloadData];
        self.emptyView.hidden = (self->_lists.count > 0);
    }];
}

- (void)refresh {
    _maxID = nil;
    _hasMore = YES;
    [self loadLists];
}

- (void)addListTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"New List"
                                                                  message:@"Enter a name for this list"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"List name";
    }];

    UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *title = alert.textFields.firstObject.text;
        if (title.length == 0) return;

        [[MAAPIClient sharedClient] createListWithTitle:title completion:^(MAList *list, NSError *error) {
            if (error || !list) return;
            [self->_lists insertObject:list atIndex:0];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }];

    [alert addAction:createAction];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _lists.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ListCell"];
        cell.textLabel.font = [MATheme fontWithSize:16];
        cell.textLabel.textColor = [MATheme textColor];
        cell.backgroundColor = [MATheme cardColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    MAList *list = _lists[indexPath.row];
    cell.textLabel.text = list.title;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        MAList *list = _lists[indexPath.row];

        [[MAAPIClient sharedClient] deleteList:list.listID completion:^(NSError *error) {
            if (!error) {
                [self->_lists removeObjectAtIndex:indexPath.row];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (editing) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                                style:UIBarButtonItemStyleDone
                                                                               target:self
                                                                               action:@selector(doneEditing)];
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)doneEditing {
    self.editing = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                         target:self
                                                                                         action:@selector(editTapped)];
}

- (void)editTapped {
    self.editing = !self.editing;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MAList *list = _lists[indexPath.row];
    MAListTimelineViewController *timeline = [[MAListTimelineViewController alloc] initWithListID:list.listID title:list.title];
    [self.navigationController pushViewController:timeline animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_hasMore && !_isLoading && indexPath.row == (NSInteger)_lists.count - 5) {
        [self loadLists];
    }
}

@end
