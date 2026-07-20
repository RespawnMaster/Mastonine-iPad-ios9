#import <UIKit/UIKit.h>

@interface MAListMembersViewController : UITableViewController

@property (nonatomic, copy) NSString *listID;
@property (nonatomic, strong) NSMutableArray *accounts;
@property (nonatomic, copy) NSString *maxID;
@property (nonatomic, assign) BOOL hasMore;

- (instancetype)initWithListID:(NSString *)listID;

@end
