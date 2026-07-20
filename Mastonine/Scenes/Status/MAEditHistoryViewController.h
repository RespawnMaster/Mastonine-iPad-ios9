#import <UIKit/UIKit.h>

@interface MAEditHistoryViewController : UITableViewController

@property (nonatomic, copy) NSString *statusID;
@property (nonatomic, strong) NSArray *edits;

- (instancetype)initWithStatusID:(NSString *)statusID;

@end
