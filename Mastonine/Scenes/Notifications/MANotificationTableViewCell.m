#import "MANotificationTableViewCell.h"
#import "MANotification.h"
#import "MAAccount.h"
#import "MAStatus.h"
#import "MATheme.h"
#import "MAHTMLRenderer.h"
#import "MAAvatarView.h"

@interface MANotificationTableViewCell ()
@property (nonatomic, strong) MAAvatarView *avatarInstance;
@end

@implementation MANotificationTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [MATheme backgroundColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _avatarInstance = [[MAAvatarView alloc] initWithFrame:CGRectZero];
        _avatarInstance.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarInstance.borderWidth = 2;
        _avatarInstance.borderColor = [MATheme primaryColor];
        _avatarView = _avatarInstance;
        [self.contentView addSubview:_avatarInstance];

        _typeIndicator = [[UIView alloc] init];
        _typeIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_typeIndicator];

        _typeLabel = [[UILabel alloc] init];
        _typeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _typeLabel.font = [MATheme boldFontWithSize:13];
        _typeLabel.numberOfLines = 1;
        [self.contentView addSubview:_typeLabel];

        _contentLabel = [[UILabel alloc] init];
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabel.font = [MATheme fontWithSize:14];
        _contentLabel.textColor = [MATheme textColor];
        _contentLabel.numberOfLines = 3;
        [self.contentView addSubview:_contentLabel];

        _timestampLabel = [[UILabel alloc] init];
        _timestampLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _timestampLabel.font = [MATheme fontWithSize:12];
        _timestampLabel.textColor = [MATheme secondaryTextColor];
        [self.contentView addSubview:_timestampLabel];

        UIView *separator = [[UIView alloc] init];
        separator.translatesAutoresizingMaskIntoConstraints = NO;
        separator.backgroundColor = [MATheme separatorColor];
        [self.contentView addSubview:separator];

        [NSLayoutConstraint activateConstraints:@[
            [_avatarInstance.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
            [_avatarInstance.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [_avatarInstance.widthAnchor constraintEqualToConstant:40],
            [_avatarInstance.heightAnchor constraintEqualToConstant:40],

            [_typeIndicator.topAnchor constraintEqualToAnchor:_avatarInstance.topAnchor],
            [_typeIndicator.trailingAnchor constraintEqualToAnchor:_avatarInstance.trailingAnchor constant:4],
            [_typeIndicator.widthAnchor constraintEqualToConstant:16],
            [_typeIndicator.heightAnchor constraintEqualToConstant:16],

            [_typeLabel.topAnchor constraintEqualToAnchor:_avatarInstance.topAnchor constant:2],
            [_typeLabel.leadingAnchor constraintEqualToAnchor:_avatarInstance.trailingAnchor constant:12],
            [_typeLabel.trailingAnchor constraintEqualToAnchor:_timestampLabel.leadingAnchor constant:-8],

            [_timestampLabel.topAnchor constraintEqualToAnchor:_avatarInstance.topAnchor constant:2],
            [_timestampLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],

            [_contentLabel.topAnchor constraintEqualToAnchor:_typeLabel.bottomAnchor constant:4],
            [_contentLabel.leadingAnchor constraintEqualToAnchor:_avatarInstance.trailingAnchor constant:12],
            [_contentLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_contentLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-12],

            [separator.leadingAnchor constraintEqualToAnchor:_avatarInstance.trailingAnchor constant:12],
            [separator.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [separator.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
            [separator.heightAnchor constraintEqualToConstant:0.5],
        ]];
    }
    return self;
}

- (void)configureWithNotification:(MANotification *)notification {
    if (!notification) return;

    [_avatarInstance configureWithAvatarURL:[notification.account avatarURL]];

    NSString *displayName = [notification.account displayNameOrUsername];
    _timestampLabel.text = [notification relativeTimeString];

    switch (notification.type) {
        case MANotificationTypeMention:
            _typeLabel.text = [NSString stringWithFormat:@"%@ mentioned you", displayName];
            _typeLabel.textColor = [MATheme primaryColor];
            _typeIndicator.backgroundColor = [MATheme primaryColor];
            break;
        case MANotificationTypeReblog:
            _typeLabel.text = [NSString stringWithFormat:@"%@ boosted your toot", displayName];
            _typeLabel.textColor = [MATheme boostColor];
            _typeIndicator.backgroundColor = [MATheme boostColor];
            break;
        case MANotificationTypeFavourite:
            _typeLabel.text = [NSString stringWithFormat:@"%@ favorited your toot", displayName];
            _typeLabel.textColor = [MATheme favoriteColor];
            _typeIndicator.backgroundColor = [MATheme favoriteColor];
            break;
        case MANotificationTypeFollow:
            _typeLabel.text = [NSString stringWithFormat:@"%@ followed you", displayName];
            _typeLabel.textColor = [MATheme accentColor];
            _typeIndicator.backgroundColor = [MATheme accentColor];
            break;
        case MANotificationTypeFollowRequest:
            _typeLabel.text = [NSString stringWithFormat:@"%@ requested to follow you", displayName];
            _typeLabel.textColor = [UIColor orangeColor];
            _typeIndicator.backgroundColor = [UIColor orangeColor];
            break;
        default:
            _typeLabel.text = [NSString stringWithFormat:@"%@ interacted with you", displayName];
            _typeLabel.textColor = [MATheme secondaryTextColor];
            _typeIndicator.backgroundColor = [MATheme secondaryTextColor];
            break;
    }

    if (notification.status) {
        NSAttributedString *content = [MAHTMLRenderer renderHTML:notification.status.content withFontSize:14.0 color:[MATheme textColor]];
        _contentLabel.attributedText = content;
        _contentLabel.hidden = NO;
    } else {
        _contentLabel.hidden = YES;
    }

    self.accessibilityLabel = _typeLabel.text;
    self.accessibilityHint = @"Double tap to view";
}

@end
