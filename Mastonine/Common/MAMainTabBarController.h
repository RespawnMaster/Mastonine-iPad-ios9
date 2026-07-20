#import <UIKit/UIKit.h>

@interface MAMainTabBarController : UITabBarController

@property (nonatomic, strong) UINavigationController *timelineNav;
@property (nonatomic, strong) UINavigationController *notificationsNav;
@property (nonatomic, strong) UINavigationController *searchNav;
@property (nonatomic, strong) UINavigationController *profileNav;

- (void)showCompose;
- (void)switchToTab:(NSInteger)index;

@end
