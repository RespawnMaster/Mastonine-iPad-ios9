#import "MAThreadViewController.h"
#import "MAStatusTableViewCell.h"
#import "MAAPIClient.h"
#import "MAStatus.h"
#import "MAAccount.h"
#import "MAMediaAttachment.h"
#import "MALoadingView.h"
#import "MATheme.h"
#import "MAComposeViewController.h"
#import "MAProfileViewController.h"
#import "MAAccountListViewController.h"
#import "MAImageViewerController.h"
#import "MATimelineViewController.h"
#import "MAWebViewController.h"
#import "MAEditHistoryViewController.h"

@interface MAThreadViewController ()

@property (nonatomic, strong) MALoadingView *loadingView;

@end

@implementation MAThreadViewController

- (instancetype)initWithStatusID:(NSString *)statusID {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _statusID = statusID;
        _allStatuses = [NSMutableArray array];
        _ancestors = @[];
        _descendants = @[];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    return [self initWithStatusID:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Thread";
    self.view.backgroundColor = [MATheme backgroundColor];
    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 200;

    [self.tableView registerClass:[MAStatusTableViewCell class] forCellReuseIdentifier:@"StatusCell"];

    _loadingView = [[MALoadingView alloc] initWithFrame:self.view.bounds];
    _loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_loadingView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusReply:) name:@"MAStatusReply" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusShare:) name:@"MAStatusShare" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusUpdated:) name:@"MAStatusUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAvatarTapped:) name:@"MAAvatarTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMediaTapped:) name:@"MAMediaTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLinkTapped:) name:@"MALinkTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleHashtagTapped:) name:@"MAHashtagTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMentionTapped:) name:@"MAMentionTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusEdit:) name:@"MAStatusEdit" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusLongPress:) name:@"MAStatusLongPress" object:nil];

    [self loadThread];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification Handlers

- (void)handleStatusReply:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *statusID = notif.userInfo[@"statusID"];
    if (!statusID) return;

    MAStatus *targetStatus = nil;
    for (MAStatus *s in _allStatuses) {
        if ([s.statusID isEqualToString:statusID]) { targetStatus = s; break; }
    }
    if (!targetStatus) return;

    MAAccount *author = targetStatus.reblogAccount ?: targetStatus.account;
    MAComposeViewController *compose = [[MAComposeViewController alloc] initWithReplyToStatusID:targetStatus.statusID
                                                                                      username:author.username];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:compose];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.navigationBar.barStyle = UIBarStyleDefault;
    nav.navigationBar.translucent = NO;
    nav.navigationBar.barTintColor = [MATheme primaryColor];
    nav.navigationBar.tintColor = [UIColor whiteColor];
    nav.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)handleStatusShare:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *statusID = notif.userInfo[@"statusID"];
    if (!statusID) return;

    MAStatus *targetStatus = nil;
    for (MAStatus *s in _allStatuses) {
        if ([s.statusID isEqualToString:statusID]) { targetStatus = s; break; }
    }
    if (!targetStatus) return;

    NSMutableArray *items = [NSMutableArray array];

    if (targetStatus.content.length > 0) {
        NSString *plainText = [self stripHTML:targetStatus.content];
        if (plainText.length > 0) [items addObject:plainText];
    }
    if (targetStatus.url.length > 0) {
        NSURL *url = [NSURL URLWithString:targetStatus.url];
        if (url) [items addObject:url];
    }
    if (items.count == 0) return;

    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        activity.modalPresentationStyle = UIModalPresentationPopover;
        activity.popoverPresentationController.sourceView = self.view;
        activity.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0, 0);
    }

    [self presentViewController:activity animated:YES completion:nil];
}

- (NSString *)stripHTML:(NSString *)html {
    if (!html) return @"";
    NSMutableString *result = [NSMutableString string];
    NSScanner *scanner = [NSScanner scannerWithString:html];
    while (![scanner isAtEnd]) {
        NSString *text = nil;
        [scanner scanUpToString:@"<" intoString:&text];
        if (text) [result appendString:text];
        [scanner scanUpToString:@">" intoString:NULL];
        [scanner scanString:@">" intoString:NULL];
    }
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)handleStatusUpdated:(NSNotification *)notif {
    MAStatus *updatedStatus = notif.userInfo[@"status"];
    if (!updatedStatus) return;

    for (NSUInteger i = 0; i < _allStatuses.count; i++) {
        MAStatus *existing = _allStatuses[i];
        if ([existing.statusID isEqualToString:updatedStatus.statusID]) {
            _allStatuses[i] = updatedStatus;
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            if ([self.tableView cellForRowAtIndexPath:path]) {
                [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
        }
    }
}

- (void)handleAvatarTapped:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *accountID = notif.userInfo[@"accountID"];
    if (!accountID) return;
    MAProfileViewController *profile = [[MAProfileViewController alloc] initWithAccountID:accountID];
    [self.navigationController pushViewController:profile animated:YES];
}

- (void)handleMediaTapped:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *statusID = notif.userInfo[@"statusID"];
    NSInteger index = [notif.userInfo[@"index"] integerValue];
    if (!statusID) return;

    for (MAStatus *s in _allStatuses) {
        if ([s.statusID isEqualToString:statusID]) {
            NSMutableArray *urls = [NSMutableArray array];
            for (MAMediaAttachment *att in s.mediaAttachments) {
                NSString *urlStr = att.url.length > 0 ? att.url : @"";
                if (urlStr.length > 0) [urls addObject:urlStr];
            }
            if (urls.count > 0) {
                MAImageViewerController *viewer = [[MAImageViewerController alloc] initWithImageURLs:urls initialIndex:index];
                [self presentViewController:viewer animated:YES completion:nil];
            }
            break;
        }
    }
}

- (void)handleLinkTapped:(NSNotification *)notif {
    if (!self.view.window) return;
    NSURL *url = notif.userInfo[@"url"];
    if (!url) return;

    MAWebViewController *webVC = [[MAWebViewController alloc] initWithURL:url];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:webVC];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)handleHashtagTapped:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *tag = notif.userInfo[@"tag"];
    if (!tag.length) return;

    MATimelineViewController *tagTimeline = [[MATimelineViewController alloc] initWithTimelineType:[NSString stringWithFormat:@"tag/%@", tag]];
    tagTimeline.title = [@"#" stringByAppendingString:tag];
    [self.navigationController pushViewController:tagTimeline animated:YES];
}

- (void)handleMentionTapped:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *acct = notif.userInfo[@"acct"];
    if (!acct.length) return;

    [[MAAPIClient sharedClient] lookupAccountWithAcct:acct completion:^(MAAccount *account, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.view.window) return;
            if (account) {
                MAProfileViewController *profile = [[MAProfileViewController alloc] initWithAccountID:account.accountID];
                [self.navigationController pushViewController:profile animated:YES];
            }
        });
    }];
}

- (void)handleStatusEdit:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *statusID = notif.userInfo[@"statusID"];
    if (!statusID) return;

    MAStatus *targetStatus = nil;
    for (MAStatus *s in _allStatuses) {
        if ([s.statusID isEqualToString:statusID]) { targetStatus = s; break; }
    }
    if (!targetStatus) return;

    NSString *plainText = @"";
    if (targetStatus.content.length > 0) {
        NSScanner *scanner = [NSScanner scannerWithString:targetStatus.content];
        NSMutableString *result = [NSMutableString string];
        while (![scanner isAtEnd]) {
            NSString *text = nil;
            [scanner scanUpToString:@"<" intoString:&text];
            if (text) [result appendString:text];
            [scanner scanUpToString:@">" intoString:NULL];
            [scanner scanString:@">" intoString:NULL];
        }
        plainText = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    MAComposeViewController *compose = [[MAComposeViewController alloc] init];
    compose.editStatusID = targetStatus.statusID;
    compose.editInitialText = plainText;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:compose];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.navigationBar.barStyle = UIBarStyleDefault;
    nav.navigationBar.translucent = NO;
    nav.navigationBar.barTintColor = [MATheme primaryColor];
    nav.navigationBar.tintColor = [UIColor whiteColor];
    nav.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)handleStatusLongPress:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *statusID = notif.userInfo[@"statusID"];
    if (!statusID) return;

    MAStatus *targetStatus = nil;
    for (MAStatus *s in _allStatuses) {
        if ([s.statusID isEqualToString:statusID]) { targetStatus = s; break; }
    }
    if (!targetStatus) return;

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Reply" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusReply" object:nil userInfo:@{@"statusID": statusID}];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:targetStatus.reblogged ? @"Unboost" : @"Boost" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (targetStatus.reblogged) {
            [[MAAPIClient sharedClient] unboostStatus:targetStatus.statusID completion:^(MAStatus *status, NSError *error) {
                if (!error) dispatch_async(dispatch_get_main_queue(), ^{ targetStatus.reblogged = NO; [self.tableView reloadData]; });
            }];
        } else {
            [[MAAPIClient sharedClient] boostStatus:targetStatus.statusID completion:^(MAStatus *status, NSError *error) {
                if (!error) dispatch_async(dispatch_get_main_queue(), ^{ targetStatus.reblogged = YES; [self.tableView reloadData]; });
            }];
        }
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:targetStatus.favourited ? @"Unfavourite" : @"Favourite" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (targetStatus.favourited) {
            [[MAAPIClient sharedClient] unfavouriteStatus:targetStatus.statusID completion:^(MAStatus *status, NSError *error) {
                if (!error) dispatch_async(dispatch_get_main_queue(), ^{ targetStatus.favourited = NO; [self.tableView reloadData]; });
            }];
        } else {
            [[MAAPIClient sharedClient] favouriteStatus:targetStatus.statusID completion:^(MAStatus *status, NSError *error) {
                if (!error) dispatch_async(dispatch_get_main_queue(), ^{ targetStatus.favourited = YES; [self.tableView reloadData]; });
            }];
        }
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:targetStatus.bookmarked ? @"Remove Bookmark" : @"Bookmark" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (targetStatus.bookmarked) {
            [[MAAPIClient sharedClient] unbookmarkStatus:targetStatus.statusID completion:^(MAStatus *status, NSError *error) {
                if (!error) dispatch_async(dispatch_get_main_queue(), ^{ targetStatus.bookmarked = NO; [self.tableView reloadData]; });
            }];
        } else {
            [[MAAPIClient sharedClient] bookmarkStatus:targetStatus.statusID completion:^(MAStatus *status, NSError *error) {
                if (!error) dispatch_async(dispatch_get_main_queue(), ^{ targetStatus.bookmarked = YES; [self.tableView reloadData]; });
            }];
        }
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusShare" object:nil userInfo:@{@"statusID": statusID}];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Reblogged By" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        MAAccountListViewController *list = [[MAAccountListViewController alloc] initWithStatusID:statusID rebloggedBy:YES];
        [self.navigationController pushViewController:list animated:YES];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Favourited By" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        MAAccountListViewController *list = [[MAAccountListViewController alloc] initWithStatusID:statusID rebloggedBy:NO];
        [self.navigationController pushViewController:list animated:YES];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Edit History" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        MAEditHistoryViewController *history = [[MAEditHistoryViewController alloc] initWithStatusID:targetStatus.statusID];
        [self.navigationController pushViewController:history animated:YES];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Copy Post Text" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *plainText = [self stripHTML:targetStatus.content];
        if (plainText.length > 0) {
            [UIPasteboard generalPasteboard].string = plainText;
        }
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Share Link" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSMutableArray *items = [NSMutableArray array];
        if (targetStatus.url.length > 0) {
            NSURL *url = [NSURL URLWithString:targetStatus.url];
            if (url) [items addObject:url];
        }
        if (items.count == 0) return;
        UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            activity.modalPresentationStyle = UIModalPresentationPopover;
            activity.popoverPresentationController.sourceView = self.view;
            activity.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0, 0);
        }
        [self presentViewController:activity animated:YES completion:nil];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        sheet.modalPresentationStyle = UIModalPresentationPopover;
        for (UITableViewCell *iterCell in [self.tableView visibleCells]) {
            if ([iterCell isKindOfClass:[MAStatusTableViewCell class]] && [((MAStatusTableViewCell *)iterCell).statusID isEqualToString:statusID]) {
                MAStatusTableViewCell *statusCell = (MAStatusTableViewCell *)iterCell;
                sheet.popoverPresentationController.sourceView = statusCell;
                sheet.popoverPresentationController.sourceRect = statusCell.moreButton.frame;
                break;
            }
        }
        if (!sheet.popoverPresentationController.sourceView) {
            sheet.popoverPresentationController.sourceView = self.view;
            sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0, 0);
        }
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - Data Loading

- (void)loadThread {
    [_loadingView showWithMessage:@"Loading thread..."];

    dispatch_group_t group = dispatch_group_create();
    __block MAStatus *mainStatus = nil;
    __block NSArray *ancestors = @[];
    __block NSArray *descendants = @[];
    __block NSError *lastError = nil;

    dispatch_group_enter(group);
    [[MAAPIClient sharedClient] fetchStatus:_statusID completion:^(MAStatus *status, NSError *error) {
        mainStatus = status;
        if (error) lastError = error;
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[MAAPIClient sharedClient] fetchContextForStatus:_statusID completion:^(NSArray *a, NSArray *d, NSError *error) {
        ancestors = a;
        descendants = d;
        if (error) lastError = error;
        dispatch_group_leave(group);
    }];

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self->_loadingView hide];

        if (!mainStatus && lastError) {
            [self showError:lastError];
            return;
        }

        self->_mainStatus = mainStatus;
        self->_ancestors = ancestors;
        self->_descendants = descendants;

        [self->_allStatuses removeAllObjects];
        [self->_allStatuses addObjectsFromArray:ancestors];
        [self->_allStatuses addObject:mainStatus];
        [self->_allStatuses addObjectsFromArray:descendants];

        self.title = [NSString stringWithFormat:@"@%@", mainStatus.account.username];
        [self.tableView reloadData];

        if (ancestors.count > 0) {
            NSIndexPath *mainPath = [NSIndexPath indexPathForRow:ancestors.count inSection:0];
            [self.tableView scrollToRowAtIndexPath:mainPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        }
    });
}

- (void)showError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                  message:error.localizedDescription
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _allStatuses.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MAStatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StatusCell" forIndexPath:indexPath];
    MAStatus *status = _allStatuses[indexPath.row];
    [cell configureWithStatus:status];

    for (UIView *v in [cell.contentView.subviews copy]) {
        if (v.tag == 9999) [v removeFromSuperview];
    }

    BOOL isMainPost = (indexPath.row == (NSInteger)_ancestors.count);

    if (isMainPost) {
        cell.cardView.layer.borderColor = [MATheme primaryColor].CGColor;
        cell.cardView.layer.borderWidth = 2;
    } else {
        cell.cardView.layer.borderWidth = 0;

        UIView *connector = [[UIView alloc] init];
        connector.translatesAutoresizingMaskIntoConstraints = NO;
        connector.backgroundColor = [MATheme separatorColor];
        connector.tag = 9999;
        [cell.contentView insertSubview:connector atIndex:0];

        [NSLayoutConstraint activateConstraints:@[
            [connector.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:42],
            [connector.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
            [connector.widthAnchor constraintEqualToConstant:2],
            [connector.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor],
        ]];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MAStatus *status = _allStatuses[indexPath.row];
    MAThreadViewController *newThread = [[MAThreadViewController alloc] initWithStatusID:status.statusID];
    [self.navigationController pushViewController:newThread animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

@end
