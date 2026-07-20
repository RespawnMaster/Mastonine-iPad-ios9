#import "MAGlobalTimelineViewController.h"
#import "MATimelineViewController.h"
#import "MATheme.h"

@implementation MAGlobalTimelineViewController

- (instancetype)initWithTimelineType:(NSString *)type {
    self = [super initWithTimelineType:type];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self.timelineType isEqualToString:@"local"]) {
        self.title = @"Local Timeline";
    } else if ([self.timelineType isEqualToString:@"federated"]) {
        self.title = @"Federated Timeline";
    }
}

@end
