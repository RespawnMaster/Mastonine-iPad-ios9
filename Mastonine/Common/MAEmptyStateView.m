#import "MAEmptyStateView.h"
#import "MATheme.h"

@implementation MAEmptyStateView

- (instancetype)initWithIcon:(NSString *)icon title:(NSString *)title subtitle:(NSString *)subtitle {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;

        _iconLabel = [[UILabel alloc] init];
        _iconLabel.hidden = YES;

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = title;
        _titleLabel.font = [MATheme boldFontWithSize:18];
        _titleLabel.textColor = [MATheme textColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.text = subtitle;
        _subtitleLabel.font = [MATheme fontWithSize:14];
        _subtitleLabel.textColor = [MATheme secondaryTextColor];
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.numberOfLines = 0;
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_subtitleLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_titleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-12],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:32],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-32],

            [_subtitleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:6],
            [_subtitleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:32],
            [_subtitleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-32],
        ]];
    }
    return self;
}

@end
