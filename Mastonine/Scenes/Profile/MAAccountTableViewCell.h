#import <UIKit/UIKit.h>

@class MAAccount;
@class MAAvatarView;

@interface MAAccountTableViewCell : UITableViewCell

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UILabel *usernameLabel;

- (void)configureWithAccount:(MAAccount *)account;

@end
