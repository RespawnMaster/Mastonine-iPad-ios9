#import "MALoadingView.h"
#import "MATheme.h"

@implementation MALoadingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [MATheme backgroundColor];
        self.hidden = YES;

        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _spinner.translatesAutoresizingMaskIntoConstraints = NO;
        _spinner.color = [MATheme primaryColor];
        [self addSubview:_spinner];

        _messageLabel = [[UILabel alloc] init];
        _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _messageLabel.textColor = [MATheme secondaryTextColor];
        _messageLabel.font = [MATheme fontWithSize:15.0];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_messageLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_spinner.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_spinner.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-20],
            [_messageLabel.topAnchor constraintEqualToAnchor:_spinner.bottomAnchor constant:12],
            [_messageLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_messageLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
            [_messageLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
        ]];
    }
    return self;
}

- (void)showWithMessage:(NSString *)message {
    self.messageLabel.text = message;
    self.hidden = NO;
    [self.spinner startAnimating];
}

- (void)hide {
    self.hidden = YES;
    [self.spinner stopAnimating];
}

@end
