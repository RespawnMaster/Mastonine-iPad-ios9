#import "MAAccountTableViewCell.h"
#import "MAAccount.h"
#import "MATheme.h"
#import "MAAvatarView.h"

@interface MAAccountTableViewCell ()
@property (nonatomic, strong) MAAvatarView *avatarInstance;
@end

@implementation MAAccountTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [MATheme backgroundColor];

        _avatarInstance = [[MAAvatarView alloc] initWithFrame:CGRectZero];
        _avatarInstance.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarInstance.borderWidth = 2;
        _avatarInstance.borderColor = [MATheme primaryColor];
        _avatarView = _avatarInstance;
        [self.contentView addSubview:_avatarInstance];

        _displayNameLabel = [[UILabel alloc] init];
        _displayNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _displayNameLabel.font = [MATheme boldFontWithSize:16];
        _displayNameLabel.textColor = [MATheme textColor];
        [self.contentView addSubview:_displayNameLabel];

        _usernameLabel = [[UILabel alloc] init];
        _usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _usernameLabel.font = [MATheme fontWithSize:13];
        _usernameLabel.textColor = [MATheme secondaryTextColor];
        [self.contentView addSubview:_usernameLabel];

        UIView *bgView = [[UIView alloc] init];
        bgView.backgroundColor = [MATheme primaryDarkColor];
        self.selectedBackgroundView = bgView;

        [NSLayoutConstraint activateConstraints:@[
            [_avatarInstance.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [_avatarInstance.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_avatarInstance.widthAnchor constraintEqualToConstant:40],
            [_avatarInstance.heightAnchor constraintEqualToConstant:40],

            [_displayNameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
            [_displayNameLabel.leadingAnchor constraintEqualToAnchor:_avatarInstance.trailingAnchor constant:12],
            [_displayNameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],

            [_usernameLabel.topAnchor constraintEqualToAnchor:_displayNameLabel.bottomAnchor constant:2],
            [_usernameLabel.leadingAnchor constraintEqualToAnchor:_avatarInstance.trailingAnchor constant:12],
            [_usernameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_usernameLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12],
        ]];
    }
    return self;
}

- (void)configureWithAccount:(MAAccount *)account {
    if (!account) return;
    _displayNameLabel.text = [account displayNameOrUsername];
    _usernameLabel.text = [NSString stringWithFormat:@"@%@", account.username];
    [_avatarInstance configureWithAvatarURL:[account avatarURL]];
    self.accessibilityLabel = [NSString stringWithFormat:@"%@, @%@", [account displayNameOrUsername], account.username];
    self.accessibilityHint = @"Double tap to view profile";
}

@end
