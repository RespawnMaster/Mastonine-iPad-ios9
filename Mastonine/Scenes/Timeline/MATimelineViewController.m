#import "MATimelineViewController.h"
#import "MAStatusTableViewCell.h"
#import "MAAPIClient.h"
#import "MAStatus.h"
#import "MAMediaAttachment.h"
#import "MALoadingView.h"
#import "MATheme.h"
#import "MAMainTabBarController.h"
#import "MAThreadViewController.h"
#import "MAProfileViewController.h"
#import "MAAccountListViewController.h"
#import "MAComposeViewController.h"
#import "MAImageViewerController.h"
#import "MAAccount.h"
#import "MAWebViewController.h"
#import "MASettingsViewController.h"
#import "MADropdownMenuViewController.h"
#import "MAList.h"
#import "MAListsViewController.h"
#import "MAManageHashtagsViewController.h"
#import "MAEditHistoryViewController.h"
#import "MASpotlightIndexer.h"

@interface MATimelineViewController () <MADropdownMenuDelegate>

@property (nonatomic, strong) MALoadingView *loadingView;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, strong) UIButton *titleButton;
@property (nonatomic, strong) NSArray *cachedLists;
@property (nonatomic, strong) NSArray *cachedHashtags;
@property (nonatomic, assign) BOOL cachedHashtagsAreTrending;

@end

@implementation MATimelineViewController

- (instancetype)initWithTimelineType:(NSString *)type {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _timelineType = type ?: @"home";
        _statuses = [NSMutableArray array];
        _hasMore = YES;
        _cachedLists = @[];
        _cachedHashtags = @[];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    return [self initWithTimelineType:@"home"];
}

- (void)viewDidLoad {
    [super viewDidLoad];

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

    _loadingView = [[MALoadingView alloc] initWithFrame:self.view.bounds];
    _loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_loadingView];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(settingsTapped)];

    [self setupTitleButton];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusReply:) name:@"MAStatusReply" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusShare:) name:@"MAStatusShare" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusUpdated:) name:@"MAStatusUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAvatarTapped:) name:@"MAAvatarTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMediaTapped:) name:@"MAMediaTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLinkTapped:) name:@"MALinkTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusEdit:) name:@"MAStatusEdit" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusLongPress:) name:@"MAStatusLongPress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleHashtagTapped:) name:@"MAHashtagTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMentionTapped:) name:@"MAMentionTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleShareReceived:) name:@"MAShareReceived" object:nil];

    [self loadInitial];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.composeButton.hidden = ![self.timelineType isEqualToString:@"home"];

    if ([self.timelineType isEqualToString:@"home"]) {
        [[[UIApplication sharedApplication] delegate] performSelector:@selector(checkForPendingShares)];
    }

    if (!self.composeButton.superview && [self.timelineType isEqualToString:@"home"]) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        btn.backgroundColor = [MATheme primaryColor];
        [btn setTitle:@"+" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:28];
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        btn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        btn.layer.cornerRadius = 28;
        btn.clipsToBounds = YES;
        btn.layer.shadowColor = [UIColor blackColor].CGColor;
        btn.layer.shadowOffset = CGSizeMake(0, 2);
        btn.layer.shadowOpacity = 0.3;
        btn.layer.shadowRadius = 4;
        [btn addTarget:self action:@selector(composeTapped) forControlEvents:UIControlEventTouchUpInside];
        self.composeButton = btn;

        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        [window addSubview:btn];

        [NSLayoutConstraint activateConstraints:@[
            [btn.trailingAnchor constraintEqualToAnchor:window.trailingAnchor constant:-20],
            [btn.bottomAnchor constraintEqualToAnchor:window.bottomAnchor constant:-69],
            [btn.widthAnchor constraintEqualToConstant:56],
            [btn.heightAnchor constraintEqualToConstant:56],
        ]];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.composeButton.hidden = YES;
}

- (void)setupTitleButton {
    _titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_titleButton addTarget:self action:@selector(titleTapped) forControlEvents:UIControlEventTouchUpInside];

    NSString *titleText = [self titleForTimeline];
    NSDictionary *attrs = @{NSFontAttributeName: [MATheme boldFontWithSize:17],
                            NSForegroundColorAttributeName: [MATheme textColor]};
    CGSize textSize = [titleText sizeWithAttributes:attrs];
    CGFloat arrowWidth = 12;

    _titleButton.frame = CGRectMake(0, 0, textSize.width + arrowWidth + 4, textSize.height + 4);

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, textSize.width, textSize.height)];
    label.text = titleText;
    label.font = [MATheme boldFontWithSize:17];
    label.textColor = [MATheme textColor];
    label.tag = 100;
    [_titleButton addSubview:label];

    UILabel *arrow = [[UILabel alloc] initWithFrame:CGRectMake(textSize.width + 2, 6, arrowWidth, textSize.height - 2)];
    arrow.text = @"\u25BE";
    arrow.font = [MATheme fontWithSize:12];
    arrow.textColor = [MATheme textColor];
    arrow.tag = 101;
    [_titleButton addSubview:arrow];

    _titleButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.navigationItem.titleView = _titleButton;
}

- (void)updateTitleButton {
    NSString *titleText = [self titleForTimeline];
    NSDictionary *attrs = @{NSFontAttributeName: [MATheme boldFontWithSize:17],
                            NSForegroundColorAttributeName: [MATheme textColor]};
    CGSize textSize = [titleText sizeWithAttributes:attrs];
    CGFloat arrowWidth = 12;

    _titleButton.frame = CGRectMake(0, 0, textSize.width + arrowWidth + 4, textSize.height + 4);

    UILabel *label = (UILabel *)[_titleButton viewWithTag:100];
    label.text = titleText;
    label.frame = CGRectMake(0, 2, textSize.width, textSize.height);

    UILabel *arrow = (UILabel *)[_titleButton viewWithTag:101];
    arrow.frame = CGRectMake(textSize.width + 2, 6, arrowWidth, textSize.height - 2);
}

- (void)titleTapped {
    [self showDropdownMenu];
}

- (void)showDropdownMenu {
    MADropdownMenuViewController *menu = [[MADropdownMenuViewController alloc] initWithStyle:UITableViewStyleGrouped];
    menu.delegate = self;
    menu.lists = self.cachedLists;
    menu.hashtags = self.cachedHashtags;
    menu.currentTimelineType = self.timelineType;

    BOOL isHashtagFeed = [self.timelineType hasPrefix:@"tag/"];
    menu.onHashtagFeed = isHashtagFeed;
    if (isHashtagFeed) {
        menu.currentHashtagName = [self.timelineType substringFromIndex:4];
        BOOL found = NO;
        for (NSDictionary *tag in self.cachedHashtags) {
            if ([tag[@"name"] isEqualToString:menu.currentHashtagName]) {
                found = YES;
                break;
            }
        }
        menu.hashtagIsFollowed = found && !self.cachedHashtagsAreTrending;
    }

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:menu];
    nav.modalPresentationStyle = UIModalPresentationPopover;
    nav.navigationBar.barStyle = UIBarStyleDefault;
    nav.navigationBar.translucent = NO;
    nav.navigationBar.barTintColor = [MATheme primaryColor];
    nav.navigationBar.tintColor = [UIColor whiteColor];
    nav.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};

    UIPopoverPresentationController *popover = nav.popoverPresentationController;
    popover.sourceView = self.titleButton;
    popover.sourceRect = self.titleButton.bounds;
    popover.permittedArrowDirections = UIPopoverArrowDirectionDown | UIPopoverArrowDirectionLeft;
    popover.backgroundColor = [MATheme cardColor];

    [self presentViewController:nav animated:YES completion:nil];

    [self loadMenuDataForMenu:menu];
}

- (void)loadMenuDataForMenu:(MADropdownMenuViewController *)menu {
    __block NSInteger pending = 2;

    void (^updateMenu)(void) = ^{
        menu.lists = self.cachedLists;
        menu.hashtags = self.cachedHashtags;
        menu.hashtagsAvailable = (self.cachedHashtags.count > 0);
        menu.hashtagsAreTrending = self.cachedHashtagsAreTrending;
        [menu reloadData];
    };

    [[MAAPIClient sharedClient] fetchListsWithCompletion:^(NSArray *result, NSError *error) {
        self.cachedLists = result ?: @[];
        pending--;
        updateMenu();
    }];

    [[MAAPIClient sharedClient] fetchFollowedHashtagsWithCompletion:^(NSArray *result, NSError *error) {
        if (result.count > 0) {
            self.cachedHashtags = [result sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
                return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
            }];
            self.cachedHashtagsAreTrending = NO;
            pending--;
            updateMenu();
            return;
        }
        [[MAAPIClient sharedClient] fetchTrendingTagsWithCompletion:^(NSArray *trending, NSError *err) {
            self.cachedHashtags = [trending sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
                return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
            }] ?: @[];
            self.cachedHashtagsAreTrending = YES;
            pending--;
            updateMenu();
        }];
    }];
}

#pragma mark - MADropdownMenuDelegate

- (void)dropdownMenuDidSelectHome {
    [self dismissViewControllerAnimated:YES completion:^{
        [self switchToTimelineType:@"home"];
    }];
}

- (void)dropdownMenuDidSelectList:(MAList *)list {
    [self dismissViewControllerAnimated:YES completion:^{
        [self switchToTimelineType:[NSString stringWithFormat:@"list/%@", list.listID]];
    }];
}

- (void)dropdownMenuDidSelectHashtag:(NSString *)tag {
    [self dismissViewControllerAnimated:YES completion:^{
        [self switchToTimelineType:[NSString stringWithFormat:@"tag/%@", tag]];
    }];
}

- (void)dropdownMenuDidSelectCreateList {
    [self dismissViewControllerAnimated:YES completion:^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"New List"
                                                                      message:@"Enter a name for this list"
                                                               preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"List name";
        }];

        [alert addAction:[UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *title = alert.textFields.firstObject.text;
            if (title.length == 0) return;

            [[MAAPIClient sharedClient] createListWithTitle:title completion:^(MAList *list, NSError *error) {
                if (error || !list) return;
                self.cachedLists = [self.cachedLists arrayByAddingObject:list];
            }];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)dropdownMenuDidSelectManageLists {
    [self dismissViewControllerAnimated:YES completion:^{
        MAListsViewController *listsVC = [[MAListsViewController alloc] initWithStyle:UITableViewStylePlain];
        [self.navigationController pushViewController:listsVC animated:YES];
    }];
}

- (void)dropdownMenuDidSelectManageHashtags {
    [self dismissViewControllerAnimated:YES completion:^{
        MAManageHashtagsViewController *vc = [[MAManageHashtagsViewController alloc] initWithStyle:UITableViewStylePlain];
        [self.navigationController pushViewController:vc animated:YES];
    }];
}

- (void)dropdownMenuDidSelectFollowHashtag {
    NSString *tag = [self.timelineType substringFromIndex:4];
    BOOL isCurrentlyFollowed = NO;
    for (NSDictionary *t in self.cachedHashtags) {
        if ([t[@"name"] isEqualToString:tag]) { isCurrentlyFollowed = YES; break; }
    }
    isCurrentlyFollowed = isCurrentlyFollowed && !self.cachedHashtagsAreTrending;

    [self dismissViewControllerAnimated:YES completion:^{
        if (isCurrentlyFollowed) {
            [[MAAPIClient sharedClient] unfollowHashtag:tag completion:^(NSError *error) {
                if (!error) {
                    [self refreshFollowedHashtags];
                }
            }];
        } else {
            [[MAAPIClient sharedClient] followHashtag:tag completion:^(NSError *error) {
                if (!error) {
                    [self refreshFollowedHashtags];
                }
            }];
        }
    }];
}

- (void)refreshFollowedHashtags {
    [[MAAPIClient sharedClient] fetchFollowedHashtagsWithCompletion:^(NSArray *result, NSError *error) {
        if (result.count > 0) {
            self.cachedHashtags = [result sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
                return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
            }];
            self.cachedHashtagsAreTrending = NO;
        }
    }];
}

- (void)switchToTimelineType:(NSString *)type {
    if ([self.timelineType isEqualToString:type]) return;
    self.timelineType = type;
    [self updateTitleButton];
    [self loadInitial];
}

- (NSString *)titleForTimeline {
    if ([_timelineType isEqualToString:@"home"]) return @"Home";
    if ([_timelineType isEqualToString:@"local"]) return @"Local";
    if ([_timelineType isEqualToString:@"federated"]) return @"Federated";
    if ([_timelineType hasPrefix:@"list/"]) {
        NSString *listID = [_timelineType substringFromIndex:5];
        for (MAList *list in self.cachedLists) {
            if ([list.listID isEqualToString:listID]) return list.title;
        }
        return @"List";
    }
    if ([_timelineType hasPrefix:@"tag/"]) {
        return [NSString stringWithFormat:@"#%@", [_timelineType substringFromIndex:4]];
    }
    return @"Timeline";
}

#pragma mark - Notification Handlers

- (NSIndexPath *)indexPathForStatusID:(NSString *)statusID {
    for (NSUInteger i = 0; i < _statuses.count; i++) {
        MAStatus *s = _statuses[i];
        if ([s.statusID isEqualToString:statusID] || [s.reblogID isEqualToString:statusID]) {
            return [NSIndexPath indexPathForRow:i inSection:0];
        }
    }
    return nil;
}

- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)handleStatusReply:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *statusID = notif.userInfo[@"statusID"];
    if (!statusID) return;

    MAStatus *targetStatus = nil;
    for (MAStatus *s in _statuses) {
        if ([s.statusID isEqualToString:statusID]) { targetStatus = s; break; }
        if ([s.reblogID isEqualToString:statusID]) { targetStatus = s; break; }
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
    for (MAStatus *s in _statuses) {
        if ([s.statusID isEqualToString:statusID]) { targetStatus = s; break; }
        if ([s.reblogID isEqualToString:statusID]) { targetStatus = s; break; }
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

- (void)handleShareReceived:(NSNotification *)notif {
    if (!self.view.window) return;
    if (![self.timelineType isEqualToString:@"home"]) return;

    NSString *text = notif.userInfo[@"text"];
    if (text.length == 0) return;

    MAComposeViewController *compose = [[MAComposeViewController alloc] init];
    compose.draftText = text;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:compose];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)handleStatusLongPress:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *statusID = notif.userInfo[@"statusID"];
    if (!statusID) return;

    MAStatus *targetStatus = nil;
    for (MAStatus *s in _statuses) {
        if ([s.statusID isEqualToString:statusID]) { targetStatus = s; break; }
        if ([s.reblogID isEqualToString:statusID]) { targetStatus = s; break; }
    }
    if (!targetStatus) return;

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Reply" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusReply" object:nil userInfo:@{@"statusID": statusID}];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:targetStatus.reblogged ? @"Unboost" : @"Boost" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSIndexPath *ip = [self indexPathForStatusID:targetStatus.statusID];
        if (targetStatus.reblogged) {
            [[MAAPIClient sharedClient] unboostStatus:targetStatus.statusID completion:^(MAStatus *status, NSError *error) {
                if (!error) dispatch_async(dispatch_get_main_queue(), ^{ targetStatus.reblogged = NO; [self reloadRowAtIndexPath:ip]; });
            }];
        } else {
            [[MAAPIClient sharedClient] boostStatus:targetStatus.statusID completion:^(MAStatus *status, NSError *error) {
                if (!error) dispatch_async(dispatch_get_main_queue(), ^{ targetStatus.reblogged = YES; [self reloadRowAtIndexPath:ip]; });
            }];
        }
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:targetStatus.favourited ? @"Unfavourite" : @"Favourite" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSIndexPath *ip = [self indexPathForStatusID:targetStatus.statusID];
        if (targetStatus.favourited) {
            [[MAAPIClient sharedClient] unfavouriteStatus:targetStatus.statusID completion:^(MAStatus *status, NSError *error) {
                if (!error) dispatch_async(dispatch_get_main_queue(), ^{ targetStatus.favourited = NO; [self reloadRowAtIndexPath:ip]; });
            }];
        } else {
            [[MAAPIClient sharedClient] favouriteStatus:targetStatus.statusID completion:^(MAStatus *status, NSError *error) {
                if (!error) dispatch_async(dispatch_get_main_queue(), ^{ targetStatus.favourited = YES; [self reloadRowAtIndexPath:ip]; });
            }];
        }
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:targetStatus.bookmarked ? @"Remove Bookmark" : @"Bookmark" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSIndexPath *ip = [self indexPathForStatusID:targetStatus.statusID];
        if (targetStatus.bookmarked) {
            [[MAAPIClient sharedClient] unbookmarkStatus:targetStatus.statusID completion:^(MAStatus *status, NSError *error) {
                if (!error) dispatch_async(dispatch_get_main_queue(), ^{ targetStatus.bookmarked = NO; [self reloadRowAtIndexPath:ip]; });
            }];
        } else {
            [[MAAPIClient sharedClient] bookmarkStatus:targetStatus.statusID completion:^(MAStatus *status, NSError *error) {
                if (!error) dispatch_async(dispatch_get_main_queue(), ^{ targetStatus.bookmarked = YES; [self reloadRowAtIndexPath:ip]; });
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

    for (MAStatus *s in _statuses) {
        if ([s.statusID isEqualToString:statusID] || [s.reblogID isEqualToString:statusID]) {
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

- (void)handleStatusEdit:(NSNotification *)notif {
    if (!self.view.window) return;
    NSString *statusID = notif.userInfo[@"statusID"];
    if (!statusID) return;

    MAStatus *targetStatus = nil;
    for (MAStatus *s in _statuses) {
        if ([s.statusID isEqualToString:statusID]) { targetStatus = s; break; }
    }
    if (!targetStatus) return;

    MAComposeViewController *compose = [[MAComposeViewController alloc] init];
    compose.editStatusID = targetStatus.statusID;
    compose.editInitialText = [self stripHTML:targetStatus.content];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:compose];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.navigationBar.barStyle = UIBarStyleDefault;
    nav.navigationBar.translucent = NO;
    nav.navigationBar.barTintColor = [MATheme primaryColor];
    nav.navigationBar.tintColor = [UIColor whiteColor];
    nav.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)handleStatusUpdated:(NSNotification *)notif {
    MAStatus *updatedStatus = notif.userInfo[@"status"];
    if (!updatedStatus) return;

    for (NSUInteger i = 0; i < _statuses.count; i++) {
        MAStatus *existing = _statuses[i];
        if ([existing.statusID isEqualToString:updatedStatus.statusID] ||
            [existing.reblogID isEqualToString:updatedStatus.statusID]) {
            if (updatedStatus.reblogAccount && !updatedStatus.account) {
                updatedStatus.account = existing.account;
            }
            _statuses[i] = updatedStatus;
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            if ([self.tableView cellForRowAtIndexPath:path]) {
                [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
        }
    }
}

#pragma mark - Data Loading

- (void)loadInitial {
    _maxID = nil;
    _hasMore = YES;
    [_loadingView showWithMessage:@"Loading..."];

    [[MAAPIClient sharedClient] fetchTimeline:_timelineType
                                         maxID:nil
                                      sinceID:nil
                                        limit:40
                                   completion:^(NSArray *statuses, NSError *error) {
        [self->_loadingView hide];
        [self.refreshControl endRefreshing];

        if (error) {
            [self showError:error];
            return;
        }

        self->_statuses = [statuses mutableCopy];
        if (statuses.count > 0) {
            MAStatus *last = statuses.lastObject;
            self->_maxID = last.statusID;
        }
        self->_hasMore = statuses.count >= 20;
        [self.tableView reloadData];

        for (MAStatus *s in self->_statuses) {
            [MASpotlightIndexer indexStatus:s];
        }
    }];
}

- (void)refresh {
    NSString *sinceID = nil;
    if (self->_statuses.count > 0) {
        sinceID = [self->_statuses.firstObject statusID];
    }

    [[MAAPIClient sharedClient] fetchTimeline:_timelineType
                                         maxID:nil
                                      sinceID:sinceID
                                        limit:40
                                   completion:^(NSArray *statuses, NSError *error) {
        [self.refreshControl endRefreshing];

        if (error || statuses.count == 0) return;

        NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
        for (NSUInteger i = 0; i < statuses.count; i++) {
            [indexes addIndex:i];
        }
        [self->_statuses insertObjects:statuses atIndexes:indexes];
        [self.tableView reloadData];
    }];
}

- (void)loadMore {
    if (_isLoading || !_hasMore) return;
    _isLoading = YES;

    [[MAAPIClient sharedClient] fetchTimeline:_timelineType
                                         maxID:_maxID
                                      sinceID:nil
                                        limit:40
                                   completion:^(NSArray *statuses, NSError *error) {
        self->_isLoading = NO;

        if (error || statuses.count == 0) {
            self->_hasMore = NO;
            return;
        }

        NSUInteger startIndex = self->_statuses.count;
        [self->_statuses addObjectsFromArray:statuses];

        if (statuses.count > 0) {
            MAStatus *last = statuses.lastObject;
            self->_maxID = last.statusID;
        }
        self->_hasMore = statuses.count >= 20;

        NSMutableArray *indexPaths = [NSMutableArray array];
        for (NSUInteger i = startIndex; i < self->_statuses.count; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)composeTapped {
    MAComposeViewController *compose = [[MAComposeViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:compose];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.navigationBar.barStyle = UIBarStyleDefault;
    nav.navigationBar.translucent = NO;
    nav.navigationBar.barTintColor = [MATheme primaryColor];
    nav.navigationBar.tintColor = [UIColor whiteColor];
    nav.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)settingsTapped {
    MASettingsViewController *settings = [[MASettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:settings animated:YES];
}

- (void)showError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                  message:error.localizedDescription
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self loadInitial];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (NSInteger)_statuses.count - 5) {
        [self loadMore];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MAStatus *status = _statuses[indexPath.row];
    MAThreadViewController *thread = [[MAThreadViewController alloc] initWithStatusID:status.statusID];
    [self.navigationController pushViewController:thread animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

@end
