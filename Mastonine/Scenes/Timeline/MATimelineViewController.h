#import <UIKit/UIKit.h>

@interface MATimelineViewController : UITableViewController

@property (nonatomic, copy) NSString *timelineType;
@property (nonatomic, strong) NSMutableArray *statuses;
@property (nonatomic, copy) NSString *maxID;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) UIButton *composeButton;

- (instancetype)initWithTimelineType:(NSString *)type;
- (void)switchToTimelineType:(NSString *)type;

@end
