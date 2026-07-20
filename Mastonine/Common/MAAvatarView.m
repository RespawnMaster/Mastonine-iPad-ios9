#import "MAAvatarView.h"
#import "MAImageCache.h"

@implementation MAAvatarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.clipsToBounds = YES;
    self.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.90 alpha:1.0];
    _borderWidth = 2.0;
    _borderColor = [UIColor colorWithRed:0.99 green:0.16 blue:0.33 alpha:1.0];
    self.layer.borderWidth = _borderWidth;
    self.layer.borderColor = _borderColor.CGColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = self.bounds.size.width / 2.0;
}

- (void)setCircularAvatar {
    self.layer.cornerRadius = self.bounds.size.width / 2.0;
    self.clipsToBounds = YES;
}

- (void)configureWithAvatarURL:(NSURL *)url {
    self.image = nil;
    if (!url) return;

    UIImage *cached = [[MAImageCache sharedCache] cachedImageForURL:url];
    if (cached) {
        self.image = cached;
        return;
    }

    [[MAImageCache sharedCache] fetchImageAtURL:url completion:^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) {
                self.image = image;
            }
        });
    }];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    self.layer.borderWidth = borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    self.layer.borderColor = borderColor.CGColor;
}

@end
