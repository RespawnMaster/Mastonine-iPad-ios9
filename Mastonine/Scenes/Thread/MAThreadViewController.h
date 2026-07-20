#import <UIKit/UIKit.h>

@class MAStatus;
@class MAAccount;
@class NSArray;

@interface MAThreadViewController : UITableViewController

@property (nonatomic, copy) NSString *statusID;
@property (nonatomic, strong) MAStatus *mainStatus;
@property (nonatomic, strong) NSArray *ancestors;
@property (nonatomic, strong) NSArray *descendants;
@property (nonatomic, strong) NSMutableArray *allStatuses;

- (instancetype)initWithStatusID:(NSString *)statusID;

@end
