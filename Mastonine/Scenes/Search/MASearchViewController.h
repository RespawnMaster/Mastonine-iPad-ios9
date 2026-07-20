#import <UIKit/UIKit.h>

@interface MASearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) NSArray *accountResults;
@property (nonatomic, strong) NSArray *statusResults;
@property (nonatomic, strong) NSArray *tagResults;
@property (nonatomic, strong) NSArray *trendingStatuses;
@property (nonatomic, strong) NSArray *suggestedAccounts;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end
