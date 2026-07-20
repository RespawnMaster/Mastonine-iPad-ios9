#import "MAMainTabBarController.h"
#import "MATimelineViewController.h"
#import "MANotificationsViewController.h"
#import "MASearchViewController.h"
#import "MAProfileViewController.h"
#import "MASettingsViewController.h"
#import "MAComposeViewController.h"
#import "MAIcons.h"
#import "MAImageCache.h"
#import "MAAPIClient.h"
#import "MAAccount.h"
#import "MATheme.h"

@implementation MAMainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = (id)self;

    MATimelineViewController *timeline = [[MATimelineViewController alloc] initWithStyle:UITableViewStylePlain];
    _timelineNav = [[UINavigationController alloc] initWithRootViewController:timeline];

    MANotificationsViewController *notifications = [[MANotificationsViewController alloc] initWithStyle:UITableViewStylePlain];
    _notificationsNav = [[UINavigationController alloc] initWithRootViewController:notifications];

    MASearchViewController *search = [[MASearchViewController alloc] init];
    _searchNav = [[UINavigationController alloc] initWithRootViewController:search];

    MAProfileViewController *profile = [[MAProfileViewController alloc] initWithStyle:UITableViewStylePlain];
    _profileNav = [[UINavigationController alloc] initWithRootViewController:profile];

    self.viewControllers = @[_timelineNav, _searchNav, _notificationsNav, _profileNav];

    NSString *homePath = [[NSBundle mainBundle] pathForResource:@"home" ofType:@"png"];
    NSString *bellPath = [[NSBundle mainBundle] pathForResource:@"bell" ofType:@"png"];
    NSString *searchPath = [[NSBundle mainBundle] pathForResource:@"search" ofType:@"png"];
    NSString *userPath = [[NSBundle mainBundle] pathForResource:@"user" ofType:@"png"];

    [_timelineNav tabBarItem].title = @"Home";
    [_timelineNav tabBarItem].image = [[UIImage imageWithContentsOfFile:homePath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    [_searchNav tabBarItem].title = @"Explore";
    [_searchNav tabBarItem].image = [[UIImage imageWithContentsOfFile:searchPath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    [_notificationsNav tabBarItem].title = @"Notifications";
    [_notificationsNav tabBarItem].image = [[UIImage imageWithContentsOfFile:bellPath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    [_profileNav tabBarItem].title = @"Profile";
    [_profileNav tabBarItem].image = [[UIImage imageWithContentsOfFile:userPath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    self.tabBar.tintColor = [MATheme primaryColor];
}

- (void)showCompose {
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

- (void)switchToTab:(NSInteger)index {
    if (index >= 0 && index < (NSInteger)[self.viewControllers count]) {
        self.selectedIndex = index;
    }
}

@end
