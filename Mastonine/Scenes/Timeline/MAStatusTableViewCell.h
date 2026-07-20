#import <UIKit/UIKit.h>

@class MAAvatarView;
@class MAStatus;
@class MAStatusToolbar;
@class MAPoll;

@interface MAStatusTableViewCell : UITableViewCell

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UILabel *boostLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) MAStatusToolbar *toolbar;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, copy) NSString *accountID;
@property (nonatomic, copy) NSString *statusID;
@property (nonatomic, strong) NSArray *mediaURLs;
@property (nonatomic, strong) UILabel *cwLabel;
@property (nonatomic, strong) UIButton *cwButton;
@property (nonatomic, assign) BOOL isRevealed;
@property (nonatomic, strong) MAPoll *poll;

- (void)configureWithStatus:(MAStatus *)status;

@end
