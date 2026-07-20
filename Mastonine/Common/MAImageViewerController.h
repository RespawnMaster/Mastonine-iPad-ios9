#import <UIKit/UIKit.h>

@interface MAImageViewerController : UIViewController

@property (nonatomic, strong) NSArray *imageURLs;
@property (nonatomic, assign) NSInteger initialIndex;

- (instancetype)initWithImageURLs:(NSArray *)urls initialIndex:(NSInteger)index;

@end
