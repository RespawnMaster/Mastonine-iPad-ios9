#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MAAccountListMode) {
    MAAccountListModeFollowers,
    MAAccountListModeFollowing,
    MAAccountListModeRebloggedBy,
    MAAccountListModeFavouritedBy,
    MAAccountListModeBlocked,
    MAAccountListModeMuted,
};

@interface MAAccountListViewController : UITableViewController

@property (nonatomic, copy) NSString *accountID;
@property (nonatomic, copy) NSString *statusID;
@property (nonatomic, copy) NSString *listTitle;
@property (nonatomic, assign) MAAccountListMode mode;

- (instancetype)initWithAccountID:(NSString *)accountID followers:(BOOL)followers;
- (instancetype)initWithStatusID:(NSString *)statusID rebloggedBy:(BOOL)reblogged;
- (instancetype)initWithBlocked;
- (instancetype)initWithMuted;

@end
