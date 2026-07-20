#import <UIKit/UIKit.h>

@interface MAListsViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *lists;
@property (nonatomic, copy) NSString *maxID;
@property (nonatomic, assign) BOOL hasMore;

@end
