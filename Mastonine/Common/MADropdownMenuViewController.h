#import <UIKit/UIKit.h>

@class MAList;

@protocol MADropdownMenuDelegate <NSObject>
- (void)dropdownMenuDidSelectHome;
- (void)dropdownMenuDidSelectList:(MAList *)list;
- (void)dropdownMenuDidSelectHashtag:(NSString *)tag;
- (void)dropdownMenuDidSelectCreateList;
- (void)dropdownMenuDidSelectManageLists;
- (void)dropdownMenuDidSelectManageHashtags;
- (void)dropdownMenuDidSelectFollowHashtag;
@end

@interface MADropdownMenuViewController : UITableViewController

@property (nonatomic, weak) id<MADropdownMenuDelegate> delegate;
@property (nonatomic, strong) NSArray *lists;
@property (nonatomic, strong) NSArray *hashtags;
@property (nonatomic, copy) NSString *currentTimelineType;
@property (nonatomic, assign) BOOL hashtagsAvailable;
@property (nonatomic, assign) BOOL hashtagsAreTrending;
@property (nonatomic, assign) BOOL onHashtagFeed;
@property (nonatomic, copy) NSString *currentHashtagName;
@property (nonatomic, assign) BOOL hashtagIsFollowed;

- (void)reloadData;

@end
