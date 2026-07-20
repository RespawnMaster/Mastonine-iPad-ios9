#import <UIKit/UIKit.h>

@protocol MAInstanceSelectionDelegate <NSObject>

- (void)instanceSelectionDidSelectInstance:(NSString *)instance;

@end

@interface MAInstanceSelectionViewController : UITableViewController

@property (nonatomic, weak) id<MAInstanceSelectionDelegate> delegate;

@end
