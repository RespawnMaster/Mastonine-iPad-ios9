#import <UIKit/UIKit.h>

@class MALoadingView;

@interface MAFavouritesViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *statuses;
@property (nonatomic, strong) MALoadingView *loadingView;
@property (nonatomic, copy) NSString *maxID;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoading;

@end
