#import <UIKit/UIKit.h>

@interface MAListTimelineViewController : UITableViewController

@property (nonatomic, copy) NSString *listID;
@property (nonatomic, strong) NSMutableArray *statuses;
@property (nonatomic, copy) NSString *maxID;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoading;

- (instancetype)initWithListID:(NSString *)listID title:(NSString *)title;

@end
