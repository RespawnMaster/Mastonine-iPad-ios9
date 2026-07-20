#import <UIKit/UIKit.h>

@class MAAvatarView;

@interface MANotificationTableViewCell : UITableViewCell

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UIView *typeIndicator;

- (void)configureWithNotification:(id)notification;

@end
