#import <UIKit/UIKit.h>

@interface MAAvatarView : UIImageView

@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, strong) UIColor *borderColor;

- (void)configureWithAvatarURL:(NSURL *)url;
- (void)setCircularAvatar;

@end
