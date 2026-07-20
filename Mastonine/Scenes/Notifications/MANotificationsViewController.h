#import <UIKit/UIKit.h>

@interface MANotificationsViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *notifications;
@property (nonatomic, copy) NSString *maxID;
@property (nonatomic, assign) BOOL isLoading;

@end
