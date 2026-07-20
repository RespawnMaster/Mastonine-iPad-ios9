#import <UIKit/UIKit.h>

@interface MAEmptyStateView : UIView

@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

- (instancetype)initWithIcon:(NSString *)icon title:(NSString *)title subtitle:(NSString *)subtitle;

@end
