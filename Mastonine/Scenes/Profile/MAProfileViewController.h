#import <UIKit/UIKit.h>

@class MAAccount;
@class MAAvatarView;

@interface MAProfileViewController : UITableViewController

@property (nonatomic, copy) NSString *accountID;
@property (nonatomic, strong) MAAccount *account;
@property (nonatomic, strong) NSArray *statuses;
@property (nonatomic, strong) UIImageView *headerImageView;
@property (nonatomic, strong) UIImageView *profileAvatar;
@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *bioLabel;
@property (nonatomic, strong) UILabel *statsLabel;
@property (nonatomic, copy) NSString *maxID;
@property (nonatomic, assign) BOOL isLoading;

- (instancetype)initWithAccountID:(NSString *)accountID;

@end
