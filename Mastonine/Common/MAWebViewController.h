#import <UIKit/UIKit.h>

@interface MAWebViewController : UIViewController

@property (nonatomic, strong) NSURL *url;

- (instancetype)initWithURL:(NSURL *)url;

@end
