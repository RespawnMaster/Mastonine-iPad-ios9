#import <UIKit/UIKit.h>

@interface MALoadingView : UIView

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UILabel *messageLabel;

- (void)showWithMessage:(NSString *)message;
- (void)hide;

@end
