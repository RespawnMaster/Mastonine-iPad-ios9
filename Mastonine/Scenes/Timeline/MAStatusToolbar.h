#import <UIKit/UIKit.h>

@interface MAStatusToolbar : UIView

@property (nonatomic, strong) UIButton *replyButton;
@property (nonatomic, strong) UIButton *boostButton;
@property (nonatomic, strong) UIButton *favouriteButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *bookmarkButton;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, copy) NSString *statusID;
@property (nonatomic, copy) NSString *ownAccountID;
@property (nonatomic, assign) BOOL isReblogged;
@property (nonatomic, assign) BOOL isFavourited;
@property (nonatomic, assign) BOOL isBookmarked;

- (void)configureWithReblogCount:(NSInteger)reblogCount
                 favouriteCount:(NSInteger)favouriteCount
                    replyCount:(NSInteger)replyCount
                      reblogged:(BOOL)reblogged
                    favourited:(BOOL)favourited
                      statusID:(NSString *)statusID;

- (void)configureWithReblogCount:(NSInteger)reblogCount
                 favouriteCount:(NSInteger)favouriteCount
                    replyCount:(NSInteger)replyCount
                      reblogged:(BOOL)reblogged
                    favourited:(BOOL)favourited
                     bookmarked:(BOOL)bookmarked
                      statusID:(NSString *)statusID;

- (void)configureWithReblogCount:(NSInteger)reblogCount
                 favouriteCount:(NSInteger)favouriteCount
                    replyCount:(NSInteger)replyCount
                      reblogged:(BOOL)reblogged
                    favourited:(BOOL)favourited
                     bookmarked:(BOOL)bookmarked
                      statusID:(NSString *)statusID
                    ownAccountID:(NSString *)ownAccountID;

@end
