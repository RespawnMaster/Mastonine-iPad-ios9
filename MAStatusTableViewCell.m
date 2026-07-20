#import "MAStatusTableViewCell.h"
#import "MAStatusToolbar.h"
#import "MAStatus.h"
#import "MAAccount.h"
#import "MAMediaAttachment.h"
#import "MAPoll.h"
#import "MATheme.h"
#import "MAHTMLRenderer.h"
#import "MAAvatarView.h"
#import "MAImageCache.h"
#import "MAAPIClient.h"

@interface MAStatusTableViewCell ()

@property (nonatomic, strong) UIView *contentWrapper;
@property (nonatomic, strong) MAAvatarView *avatarInstance;
@property (nonatomic, strong) UIView *mediaContainer;
@property (nonatomic, strong) NSMutableArray *mediaImageViews;
@property (nonatomic, strong) NSLayoutConstraint *contentTopToUsername;
@property (nonatomic, strong) NSLayoutConstraint *contentTopToCWButton;
@property (nonatomic, strong) MAStatus *currentStatus;
@property (nonatomic, strong) UIView *pollContainer;
@property (nonatomic, strong) NSMutableArray *pollOptionViews;
@property (nonatomic, strong) UIView *pollProgressBackgrounds;
@property (nonatomic, strong) UIButton *pollVoteButton;
@property (nonatomic, strong) NSMutableArray *pollOptionButtons;
@property (nonatomic, strong) NSMutableArray *selectedPollIndices;
@property (nonatomic, strong) NSLayoutConstraint *toolbarTopToMedia;
@property (nonatomic, strong) NSLayoutConstraint *toolbarTopToPoll;
@property (nonatomic, strong) NSLayoutConstraint *avatarTopToCard;
@property (nonatomic, strong) NSLayoutConstraint *avatarTopToBoost;

@end

@implementation MAStatusTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [MATheme backgroundColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = [MATheme cardColor];
        _cardView.layer.cornerRadius = 0;
        _cardView.clipsToBounds = YES;
        _cardView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_cardView];

        _avatarInstance = [[MAAvatarView alloc] initWithFrame:CGRectZero];
        _avatarInstance.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarInstance.borderWidth = 2;
        _avatarInstance.borderColor = [MATheme primaryColor];
        _avatarInstance.backgroundColor = [MATheme cardColor];
        _avatarView = _avatarInstance;
        _avatarInstance.userInteractionEnabled = YES;
        UITapGestureRecognizer *avatarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTapped)];
        [_avatarInstance addGestureRecognizer:avatarTap];
        _avatarInstance.accessibilityLabel = @"View profile";
        _avatarInstance.accessibilityTraits = UIAccessibilityTraitButton;
        [_cardView addSubview:_avatarInstance];

        _boostLabel = [[UILabel alloc] init];
        _boostLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _boostLabel.font = [MATheme lightFontWithSize:13];
        _boostLabel.textColor = [MATheme boostColor];
        _boostLabel.hidden = YES;
        [_cardView addSubview:_boostLabel];

        _displayNameLabel = [[UILabel alloc] init];
        _displayNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _displayNameLabel.font = [MATheme boldFontWithSize:16];
        _displayNameLabel.textColor = [MATheme textColor];
        _displayNameLabel.numberOfLines = 1;
        [_cardView addSubview:_displayNameLabel];

        _usernameLabel = [[UILabel alloc] init];
        _usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _usernameLabel.font = [MATheme fontWithSize:14];
        _usernameLabel.textColor = [MATheme secondaryTextColor];
        _usernameLabel.numberOfLines = 1;
        [_cardView addSubview:_usernameLabel];

        _timestampLabel = [[UILabel alloc] init];
        _timestampLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _timestampLabel.font = [MATheme fontWithSize:13];
        _timestampLabel.textColor = [MATheme secondaryTextColor];
        _timestampLabel.textAlignment = NSTextAlignmentRight;
        [_cardView addSubview:_timestampLabel];

        _moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _moreButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_moreButton setTitle:@"\u25BE" forState:UIControlStateNormal];
        [_moreButton setTitleColor:[MATheme secondaryTextColor] forState:UIControlStateNormal];
        _moreButton.titleLabel.font = [MATheme fontWithSize:18];
        [_moreButton addTarget:self action:@selector(moreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        _moreButton.accessibilityLabel = @"More options";
        [_cardView addSubview:_moreButton];

        _cwLabel = [[UILabel alloc] init];
        _cwLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _cwLabel.font = [MATheme boldFontWithSize:14];
        _cwLabel.textColor = [MATheme textColor];
        _cwLabel.numberOfLines = 0;
        _cwLabel.hidden = YES;
        _cwLabel.backgroundColor = [UIColor colorWithRed:1.0 green:0.95 blue:0.85 alpha:1.0];
        _cwLabel.layer.cornerRadius = 4;
        _cwLabel.clipsToBounds = YES;
        [_cardView addSubview:_cwLabel];

        _cwButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _cwButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_cwButton setTitle:@"Show content" forState:UIControlStateNormal];
        [_cwButton setTitleColor:[MATheme primaryColor] forState:UIControlStateNormal];
        _cwButton.titleLabel.font = [MATheme boldFontWithSize:14];
        _cwButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _cwButton.hidden = YES;
        [_cwButton addTarget:self action:@selector(cwTapped) forControlEvents:UIControlEventTouchUpInside];
        _cwButton.accessibilityLabel = @"Toggle content warning";
        [_cardView addSubview:_cwButton];

        _contentLabel = [[UILabel alloc] init];
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabel.numberOfLines = 0;
        _contentLabel.textColor = [MATheme textColor];
        _contentLabel.font = [MATheme fontWithSize:15];
        UITapGestureRecognizer *contentTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentTapped:)];
        _contentLabel.userInteractionEnabled = YES;
        [_contentLabel addGestureRecognizer:contentTap];
        [_cardView addSubview:_contentLabel];

        _mediaContainer = [[UIView alloc] init];
        _mediaContainer.translatesAutoresizingMaskIntoConstraints = NO;
        _mediaContainer.clipsToBounds = YES;
        _mediaContainer.layer.cornerRadius = 8;
        [_cardView addSubview:_mediaContainer];

        _mediaImageViews = [NSMutableArray array];

        _pollContainer = [[UIView alloc] init];
        _pollContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [_cardView addSubview:_pollContainer];

        _pollOptionViews = [NSMutableArray array];
        _pollOptionButtons = [NSMutableArray array];
        _selectedPollIndices = [NSMutableArray array];

        _pollVoteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _pollVoteButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_pollVoteButton setTitle:@"Vote" forState:UIControlStateNormal];
        [_pollVoteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _pollVoteButton.titleLabel.font = [MATheme boldFontWithSize:14];
        _pollVoteButton.backgroundColor = [MATheme primaryColor];
        _pollVoteButton.layer.cornerRadius = 6;
        _pollVoteButton.clipsToBounds = YES;
        _pollVoteButton.hidden = YES;
        [_pollVoteButton addTarget:self action:@selector(pollVoteTapped) forControlEvents:UIControlEventTouchUpInside];
        _pollVoteButton.accessibilityLabel = @"Vote";
        [_pollContainer addSubview:_pollVoteButton];

        _toolbar = [[MAStatusToolbar alloc] init];
        _toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        [_cardView addSubview:_toolbar];

        _avatarTopToCard = [_avatarInstance.topAnchor constraintEqualToAnchor:_cardView.topAnchor constant:10];
        _avatarTopToBoost = [_avatarInstance.topAnchor constraintEqualToAnchor:_boostLabel.bottomAnchor constant:8];
        _avatarTopToBoost.active = NO;

        _contentTopToUsername = [_contentLabel.topAnchor constraintEqualToAnchor:_usernameLabel.bottomAnchor constant:8];
        _contentTopToCWButton = [_contentLabel.topAnchor constraintEqualToAnchor:_cwButton.bottomAnchor constant:8];
        _contentTopToCWButton.active = NO;
        _contentTopToUsername.active = YES;

        _toolbarTopToMedia = [_toolbar.topAnchor constraintEqualToAnchor:_mediaContainer.bottomAnchor constant:8];
        _toolbarTopToPoll = [_toolbar.topAnchor constraintEqualToAnchor:_pollContainer.bottomAnchor constant:8];
        _toolbarTopToMedia.active = YES;
        _toolbarTopToPoll.active = NO;

        [NSLayoutConstraint activateConstraints:@[
            [_cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
            [_cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
            [_cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
            [_cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],

            [_boostLabel.topAnchor constraintEqualToAnchor:_cardView.topAnchor constant:8],
            [_boostLabel.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:10],
            [_boostLabel.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-10],

            _avatarTopToCard,

            [_avatarInstance.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:10],
            [_avatarInstance.widthAnchor constraintEqualToConstant:40],
            [_avatarInstance.heightAnchor constraintEqualToConstant:40],

            [_displayNameLabel.topAnchor constraintEqualToAnchor:_avatarInstance.topAnchor constant:0],
            [_displayNameLabel.leadingAnchor constraintEqualToAnchor:_avatarInstance.trailingAnchor constant:10],
            [_displayNameLabel.trailingAnchor constraintEqualToAnchor:_moreButton.leadingAnchor constant:-2],

            [_usernameLabel.topAnchor constraintEqualToAnchor:_displayNameLabel.bottomAnchor constant:2],
            [_usernameLabel.leadingAnchor constraintEqualToAnchor:_avatarInstance.trailingAnchor constant:10],
            [_usernameLabel.trailingAnchor constraintEqualToAnchor:_moreButton.leadingAnchor constant:-2],

            [_timestampLabel.centerYAnchor constraintEqualToAnchor:_displayNameLabel.centerYAnchor],
            [_timestampLabel.trailingAnchor constraintEqualToAnchor:_moreButton.leadingAnchor constant:-2],
            [_timestampLabel.widthAnchor constraintGreaterThanOrEqualToConstant:50],

            [_moreButton.centerYAnchor constraintEqualToAnchor:_displayNameLabel.centerYAnchor],
            [_moreButton.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-8],
            [_moreButton.widthAnchor constraintEqualToConstant:24],
            [_moreButton.heightAnchor constraintEqualToConstant:24],

            [_cwLabel.topAnchor constraintEqualToAnchor:_usernameLabel.bottomAnchor constant:8],
            [_cwLabel.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:12],
            [_cwLabel.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-12],

            [_cwButton.topAnchor constraintEqualToAnchor:_cwLabel.bottomAnchor constant:4],
            [_cwButton.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:12],
            [_cwButton.heightAnchor constraintEqualToConstant:30],

            [_contentLabel.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:12],
            [_contentLabel.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-12],

            [_mediaContainer.topAnchor constraintEqualToAnchor:_contentLabel.bottomAnchor constant:8],
            [_mediaContainer.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:12],
            [_mediaContainer.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-12],
            [_mediaContainer.heightAnchor constraintEqualToConstant:0],

            [_pollContainer.topAnchor constraintEqualToAnchor:_mediaContainer.bottomAnchor constant:8],
            [_pollContainer.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:12],
            [_pollContainer.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-12],

            [_pollVoteButton.topAnchor constraintEqualToAnchor:_pollContainer.bottomAnchor constant:6],
            [_pollVoteButton.widthAnchor constraintEqualToConstant:80],
            [_pollVoteButton.heightAnchor constraintEqualToConstant:32],
            [_pollVoteButton.centerXAnchor constraintEqualToAnchor:_pollContainer.centerXAnchor],
            [_pollVoteButton.bottomAnchor constraintEqualToAnchor:_pollContainer.bottomAnchor],

            [_toolbar.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:4],
            [_toolbar.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-4],
            [_toolbar.bottomAnchor constraintEqualToAnchor:_cardView.bottomAnchor constant:-8],
            [_toolbar.heightAnchor constraintEqualToConstant:40],
        ]];

    }
    return self;
}

- (void)moreButtonTapped {
    if (self.statusID) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusLongPress" object:nil userInfo:@{@"statusID": self.statusID}];
    }
}

- (void)configureWithStatus:(MAStatus *)status {
    if (!status) return;

    _currentStatus = status;
    _isRevealed = NO;

    MAAccount *displayAccount = status.reblogAccount ?: status.account;

    _accountID = displayAccount.accountID;
    _statusID = status.statusID;

    [_avatarInstance configureWithAvatarURL:[displayAccount avatarURL]];
    _avatarInstance.layer.cornerRadius = 24;

    NSString *display = [displayAccount displayNameOrUsername];
    _displayNameLabel.text = display;
    _usernameLabel.text = [NSString stringWithFormat:@"@%@", displayAccount.username];
    _timestampLabel.text = [status relativeTimeString];

    NSAttributedString *attributedContent = [MAHTMLRenderer renderHTML:status.content withFontSize:15.0 color:[MATheme textColor]];
    _contentLabel.attributedText = attributedContent;

    if (status.reblogAccount) {
        _boostLabel.hidden = NO;
        _boostLabel.text = [NSString stringWithFormat:@"%@ boosted", [status.reblogAccount displayNameOrUsername]];
        _avatarTopToCard.active = NO;
        _avatarTopToBoost.active = YES;
    } else {
        _boostLabel.hidden = YES;
        _avatarTopToBoost.active = NO;
        _avatarTopToCard.active = YES;
    }

    BOOL hasCW = (status.spoilerText.length > 0) || status.sensitive;

    if (hasCW) {
        if (status.spoilerText.length > 0) {
            _cwLabel.text = [NSString stringWithFormat:@"Content warning: %@", status.spoilerText];
        } else {
            _cwLabel.text = @"Sensitive content";
        }
        _cwLabel.hidden = NO;
        [_cwButton setTitle:@"Show content" forState:UIControlStateNormal];
        _cwButton.hidden = NO;
        _contentLabel.hidden = YES;
        _contentTopToUsername.active = NO;
        _contentTopToCWButton.active = YES;
    } else {
        _cwLabel.hidden = YES;
        _cwLabel.text = nil;
        _cwButton.hidden = YES;
        _contentLabel.hidden = NO;
        _contentTopToCWButton.active = NO;
        _contentTopToUsername.active = YES;
    }

    [self configureMediaAttachments:status.mediaAttachments];

    if (hasCW) {
        _mediaContainer.hidden = YES;
    }

    [self configurePoll:status.poll];

    _toolbarTopToMedia.active = YES;
    _toolbarTopToPoll.active = NO;

    if (status.poll && !_mediaContainer.hidden) {
        _toolbarTopToMedia.active = NO;
        _toolbarTopToPoll.active = YES;
    } else if (status.poll) {
        _toolbarTopToMedia.active = NO;
        _toolbarTopToPoll.active = YES;
    }

    NSString *ownID = [MAAPIClient sharedClient].currentAccountID;
    NSString *toolbarOwnID = nil;
    if (ownID.length > 0 && status.account && [ownID isEqualToString:status.account.accountID]) {
        toolbarOwnID = ownID;
    }

    [_toolbar configureWithReblogCount:status.reblogsCount
                       favouriteCount:status.favouritesCount
                          replyCount:status.repliesCount
                            reblogged:status.reblogged
                          favourited:status.favourited
                           bookmarked:status.bookmarked
                            statusID:status.statusID
                          ownAccountID:toolbarOwnID];
}

- (void)configurePoll:(MAPoll *)poll {
    for (UIView *v in _pollOptionViews) [v removeFromSuperview];
    [_pollOptionViews removeAllObjects];
    [_pollOptionButtons removeAllObjects];
    [_selectedPollIndices removeAllObjects];

    if (!poll) {
        _pollContainer.hidden = YES;
        _pollVoteButton.hidden = YES;
        for (NSLayoutConstraint *c in _pollContainer.constraints) {
            if (c.firstAttribute == NSLayoutAttributeHeight) {
                c.constant = 0;
                break;
            }
        }
        return;
    }

    _pollContainer.hidden = NO;
    _poll = poll;

    BOOL hasVoted = poll.ownVotes.count > 0;
    BOOL showResults = poll.expired || hasVoted;

    CGFloat containerWidth = [UIScreen mainScreen].bounds.size.width - 48;
    CGFloat optionHeight = 36;
    CGFloat spacing = 6;

    for (NSInteger i = 0; i < (NSInteger)poll.options.count && i < 4; i++) {
        NSDictionary *option = poll.options[i];
        NSString *title = option[@"title"] ?: @"";
        NSInteger votesCount = [option[@"votes_count"] integerValue];

        UIView *optionView = [[UIView alloc] init];
        optionView.translatesAutoresizingMaskIntoConstraints = NO;
        optionView.layer.cornerRadius = 6;
        optionView.clipsToBounds = YES;
        optionView.backgroundColor = [MATheme cardColor];
        optionView.layer.borderColor = [MATheme separatorColor].CGColor;
        optionView.layer.borderWidth = 1;
        [_pollContainer addSubview:optionView];
        [_pollOptionViews addObject:optionView];

        UIView *progressBar = [[UIView alloc] init];
        progressBar.translatesAutoresizingMaskIntoConstraints = NO;
        progressBar.backgroundColor = [MATheme primaryColor];
        progressBar.alpha = 0.2;
        progressBar.tag = 100 + i;
        [optionView addSubview:progressBar];

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.font = [MATheme fontWithSize:14];
        titleLabel.textColor = [MATheme textColor];
        titleLabel.text = title;
        [optionView addSubview:titleLabel];

        UILabel *percentLabel = [[UILabel alloc] init];
        percentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        percentLabel.font = [MATheme boldFontWithSize:13];
        percentLabel.textColor = [MATheme secondaryTextColor];
        percentLabel.textAlignment = NSTextAlignmentRight;
        percentLabel.tag = 200 + i;
        [optionView addSubview:percentLabel];

        if (showResults && poll.votesCount > 0) {
            CGFloat percent = (CGFloat)votesCount / (CGFloat)poll.votesCount;
            percentLabel.text = [NSString stringWithFormat:@"%.0f%%", percent * 100];

            for (NSLayoutConstraint *c in progressBar.constraints) {
                if (c.firstAttribute == NSLayoutAttributeWidth) {
                    c.constant = containerWidth * percent;
                    break;
                }
            }
        } else {
            percentLabel.text = @"";
        }

        [NSLayoutConstraint activateConstraints:@[
            [optionView.leadingAnchor constraintEqualToAnchor:_pollContainer.leadingAnchor],
            [optionView.trailingAnchor constraintEqualToAnchor:_pollContainer.trailingAnchor],
            [optionView.heightAnchor constraintEqualToConstant:optionHeight],

            [progressBar.leadingAnchor constraintEqualToAnchor:optionView.leadingAnchor],
            [progressBar.topAnchor constraintEqualToAnchor:optionView.topAnchor],
            [progressBar.bottomAnchor constraintEqualToAnchor:optionView.bottomAnchor],
            [progressBar.widthAnchor constraintEqualToConstant:0],

            [titleLabel.leadingAnchor constraintEqualToAnchor:optionView.leadingAnchor constant:10],
            [titleLabel.trailingAnchor constraintEqualToAnchor:percentLabel.leadingAnchor constant:-8],
            [titleLabel.centerYAnchor constraintEqualToAnchor:optionView.centerYAnchor],

            [percentLabel.trailingAnchor constraintEqualToAnchor:optionView.trailingAnchor constant:-10],
            [percentLabel.centerYAnchor constraintEqualToAnchor:optionView.centerYAnchor],
            [percentLabel.widthAnchor constraintGreaterThanOrEqualToConstant:45],
        ]];

        if (i == 0) {
            [optionView.topAnchor constraintEqualToAnchor:_pollContainer.topAnchor].active = YES;
        } else {
            UIView *prev = _pollOptionViews[i - 1];
            [optionView.topAnchor constraintEqualToAnchor:prev.bottomAnchor constant:spacing].active = YES;
        }

        if (!showResults) {
            UIButton *tapButton = [UIButton buttonWithType:UIButtonTypeCustom];
            tapButton.translatesAutoresizingMaskIntoConstraints = NO;
            tapButton.tag = i;
            [tapButton addTarget:self action:@selector(pollOptionTapped:) forControlEvents:UIControlEventTouchUpInside];
            [optionView addSubview:tapButton];
            [NSLayoutConstraint activateConstraints:@[
                [tapButton.topAnchor constraintEqualToAnchor:optionView.topAnchor],
                [tapButton.bottomAnchor constraintEqualToAnchor:optionView.bottomAnchor],
                [tapButton.leadingAnchor constraintEqualToAnchor:optionView.leadingAnchor],
                [tapButton.trailingAnchor constraintEqualToAnchor:optionView.trailingAnchor],
            ]];
            [_pollOptionButtons addObject:tapButton];
        }
    }

    UIView *lastOption = _pollOptionViews.lastObject;
    if (lastOption) {
        [_pollContainer.bottomAnchor constraintEqualToAnchor:lastOption.bottomAnchor].active = YES;
    }

    if (!showResults && poll.options.count > 0) {
        _pollVoteButton.hidden = NO;
    } else {
        _pollVoteButton.hidden = YES;

        UILabel *votesLabel = [[UILabel alloc] init];
        votesLabel.translatesAutoresizingMaskIntoConstraints = NO;
        votesLabel.font = [MATheme lightFontWithSize:12];
        votesLabel.textColor = [MATheme secondaryTextColor];
        votesLabel.text = [NSString stringWithFormat:@"%ld votes", (long)poll.votesCount];
        [_pollContainer addSubview:votesLabel];

        [NSLayoutConstraint activateConstraints:@[
            [votesLabel.topAnchor constraintEqualToAnchor:lastOption.bottomAnchor constant:6],
            [votesLabel.centerXAnchor constraintEqualToAnchor:_pollContainer.centerXAnchor],
            [votesLabel.bottomAnchor constraintEqualToAnchor:_pollContainer.bottomAnchor],
        ]];
    }

    if (_pollVoteButton.hidden && !showResults) {
        [_pollContainer.bottomAnchor constraintEqualToAnchor:lastOption.bottomAnchor].active = YES;
    }
}

- (void)pollOptionTapped:(UIButton *)sender {
    NSInteger index = sender.tag;

    if (_poll.multiple) {
        BOOL found = NO;
        for (NSInteger i = 0; i < (NSInteger)_selectedPollIndices.count; i++) {
            if ([_selectedPollIndices[i] integerValue] == index) {
                [_selectedPollIndices removeObjectAtIndex:i];
                found = YES;
                break;
            }
        }
        if (!found) {
            [_selectedPollIndices addObject:@(index)];
        }
    } else {
        [_selectedPollIndices removeAllObjects];
        [_selectedPollIndices addObject:@(index)];
    }

    for (NSInteger i = 0; i < (NSInteger)_pollOptionViews.count; i++) {
        UIView *optionView = _pollOptionViews[i];
        BOOL selected = NO;
        for (NSNumber *idx in _selectedPollIndices) {
            if ([idx integerValue] == i) { selected = YES; break; }
        }
        optionView.layer.borderColor = selected ? [MATheme primaryColor].CGColor : [MATheme separatorColor].CGColor;
        optionView.layer.borderWidth = selected ? 2 : 1;
    }
}

- (void)pollVoteTapped {
    if (_selectedPollIndices.count == 0) return;

    NSMutableArray *choices = [NSMutableArray array];
    for (NSNumber *idx in _selectedPollIndices) {
        [choices addObject:idx];
    }

    _pollVoteButton.enabled = NO;
    [_pollVoteButton setTitle:@"..." forState:UIControlStateNormal];

    [[MAAPIClient sharedClient] voteOnPoll:_poll.pollID choices:choices completion:^(MAPoll *newPoll, NSError *error) {
        self->_pollVoteButton.enabled = YES;
        [self->_pollVoteButton setTitle:@"Vote" forState:UIControlStateNormal];

        if (error || !newPoll) return;

        self->_poll = newPoll;
        [self configurePoll:newPoll];
    }];
}

- (void)cwTapped {
    _isRevealed = !_isRevealed;

    if (_isRevealed) {
        [_cwButton setTitle:@"Hide content" forState:UIControlStateNormal];
        _cwLabel.hidden = YES;
        _contentLabel.hidden = NO;
    } else {
        [_cwButton setTitle:@"Show content" forState:UIControlStateNormal];
        if (_currentStatus.spoilerText.length > 0) {
            _cwLabel.text = [NSString stringWithFormat:@"Content warning: %@", _currentStatus.spoilerText];
        } else {
            _cwLabel.text = @"Sensitive content";
        }
        _cwLabel.hidden = NO;
        _contentLabel.hidden = YES;
    }

    [self configureMediaAttachments:_currentStatus.mediaAttachments];

    if (!_isRevealed && ((_currentStatus.spoilerText.length > 0) || _currentStatus.sensitive)) {
        _mediaContainer.hidden = YES;
    }

    if (_isRevealed) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (void)contentTapped:(UITapGestureRecognizer *)gesture {
    NSAttributedString *attrText = _contentLabel.attributedText;
    if (attrText.length == 0) {
        if (_currentStatus.url.length > 0) {
            NSURL *url = [NSURL URLWithString:_currentStatus.url];
            if (url) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MALinkTapped"
                                                                    object:nil
                                                                  userInfo:@{@"url": url}];
            }
        }
        return;
    }

    CGPoint tapPoint = [gesture locationInView:_contentLabel];
    CGFloat labelWidth = _contentLabel.bounds.size.width;
    if (labelWidth <= 0) return;

    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:attrText];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(labelWidth, CGFLOAT_MAX)];
    textContainer.lineFragmentPadding = 0;
    textContainer.maximumNumberOfLines = 0;
    [layoutManager addTextContainer:textContainer];

    __block NSString *foundURL = nil;

    [attrText enumerateAttribute:@"MALinkURL" inRange:NSMakeRange(0, attrText.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (![value isKindOfClass:[NSString class]] || [(NSString *)value length] == 0) return;
        if (range.location == NSNotFound) return;

        NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
        CGRect rect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
        CGRect expanded = CGRectInset(rect, -2, -4);

        if (CGRectContainsPoint(expanded, tapPoint)) {
            foundURL = value;
            *stop = YES;
        }
    }];

    if (foundURL.length > 0) {
        NSString *tag = nil;
        if ([foundURL hasPrefix:@"/tags/"]) {
            tag = [foundURL substringFromIndex:6];
        } else if ([foundURL rangeOfString:@"/tags/"].location != NSNotFound) {
            NSRange range = [foundURL rangeOfString:@"/tags/"];
            tag = [foundURL substringFromIndex:range.location + range.length];
            NSRange queryRange = [tag rangeOfString:@"?"];
            if (queryRange.location != NSNotFound) tag = [tag substringToIndex:queryRange.location];
            NSRange hashRange = [tag rangeOfString:@"#"];
            if (hashRange.location != NSNotFound) tag = [tag substringToIndex:hashRange.location];
        }
        if (tag.length > 0) {
            tag = [tag stringByRemovingPercentEncoding] ?: tag;
            if (tag.length > 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MAHashtagTapped"
                                                                    object:nil
                                                                  userInfo:@{@"tag": tag}];
                return;
            }
        }

        if ([foundURL hasPrefix:@"/@"]) {
            NSString *acct = [foundURL substringFromIndex:2];
            NSRange queryRange = [acct rangeOfString:@"?"];
            if (queryRange.location != NSNotFound) acct = [acct substringToIndex:queryRange.location];
            acct = [acct stringByRemovingPercentEncoding] ?: acct;
            if (acct.length > 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MAMentionTapped"
                                                                    object:nil
                                                                  userInfo:@{@"acct": acct}];
                return;
            }
        } else if ([foundURL rangeOfString:@"/@"].location != NSNotFound) {
            NSRange atRange = [foundURL rangeOfString:@"/@"];
            NSString *acct = [foundURL substringFromIndex:atRange.location + atRange.length];
            NSRange queryRange = [acct rangeOfString:@"?"];
            if (queryRange.location != NSNotFound) acct = [acct substringToIndex:queryRange.location];
            acct = [acct stringByRemovingPercentEncoding] ?: acct;
            if (acct.length > 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MAMentionTapped"
                                                                    object:nil
                                                                  userInfo:@{@"acct": acct}];
                return;
            }
        }

        NSURL *linkAsURL = [NSURL URLWithString:foundURL];
        if (linkAsURL) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MALinkTapped"
                                                                object:nil
                                                              userInfo:@{@"url": linkAsURL}];
            return;
        }
        NSURL *baseURL = [MAAPIClient sharedClient].baseURL;
        if (baseURL) {
            NSURL *url = [NSURL URLWithString:foundURL relativeToURL:baseURL];
            if (url) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MALinkTapped"
                                                                    object:nil
                                                                  userInfo:@{@"url": url}];
                return;
            }
        }
    }
}

- (void)configureMediaAttachments:(NSArray *)attachments {
    for (UIView *v in _mediaImageViews) [v removeFromSuperview];
    [_mediaImageViews removeAllObjects];

    if (!attachments || attachments.count == 0) {
        for (NSLayoutConstraint *c in _mediaContainer.constraints) {
            if (c.firstAttribute == NSLayoutAttributeHeight) {
                c.constant = 0;
                break;
            }
        }
        _mediaContainer.hidden = YES;
        return;
    }

    _mediaContainer.hidden = NO;
    NSInteger count = MIN(attachments.count, (NSUInteger)4);
    CGFloat spacing = 4;
    CGFloat containerWidth = [UIScreen mainScreen].bounds.size.width - 48;

    NSMutableArray *urls = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i++) {
        MAMediaAttachment *att = attachments[i];
        NSString *urlStr = att.previewURL.length > 0 ? att.previewURL : att.url;
        if (urlStr.length > 0) [urls addObject:urlStr];
    }
    _mediaURLs = urls;

    CGFloat mediaHeight;
    if (count == 1) {
        mediaHeight = containerWidth * 0.6;
    } else {
        mediaHeight = containerWidth * 0.45;
    }

    for (NSLayoutConstraint *c in _mediaContainer.constraints) {
        if (c.firstAttribute == NSLayoutAttributeHeight) {
            c.constant = mediaHeight;
            break;
        }
    }

    for (NSInteger i = 0; i < count; i++) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.backgroundColor = [MATheme separatorColor];
        imageView.userInteractionEnabled = YES;
        imageView.layer.cornerRadius = 4;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mediaTapped:)];
        imageView.tag = i;
        [imageView addGestureRecognizer:tap];

        [_mediaContainer addSubview:imageView];
        [_mediaImageViews addObject:imageView];

        NSString *urlStr = (i < (NSInteger)urls.count) ? urls[i] : nil;
        if (urlStr.length > 0) {
            NSURL *url = [NSURL URLWithString:urlStr];
            if (url) {
                CGFloat thumbSize = (UIScreen.mainScreen.scale > 1.0) ? 300 : 150;
                CGSize targetSize = CGSizeMake(thumbSize, thumbSize);
                [[MAImageCache sharedCache] fetchImageAtURL:url size:targetSize completion:^(UIImage *image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        imageView.image = image;
                    });
                }];
            }
        }
    }

    if (count == 1) {
        UIImageView *iv = _mediaImageViews[0];
        [NSLayoutConstraint activateConstraints:@[
            [iv.topAnchor constraintEqualToAnchor:_mediaContainer.topAnchor],
            [iv.leadingAnchor constraintEqualToAnchor:_mediaContainer.leadingAnchor],
            [iv.trailingAnchor constraintEqualToAnchor:_mediaContainer.trailingAnchor],
            [iv.bottomAnchor constraintEqualToAnchor:_mediaContainer.bottomAnchor],
        ]];
    } else if (count == 2) {
        UIImageView *left = _mediaImageViews[0];
        UIImageView *right = _mediaImageViews[1];
        [NSLayoutConstraint activateConstraints:@[
            [left.topAnchor constraintEqualToAnchor:_mediaContainer.topAnchor],
            [left.leadingAnchor constraintEqualToAnchor:_mediaContainer.leadingAnchor],
            [left.bottomAnchor constraintEqualToAnchor:_mediaContainer.bottomAnchor],
            [left.widthAnchor constraintEqualToAnchor:_mediaContainer.widthAnchor multiplier:0.5 constant:-spacing/2],

            [right.topAnchor constraintEqualToAnchor:_mediaContainer.topAnchor],
            [right.trailingAnchor constraintEqualToAnchor:_mediaContainer.trailingAnchor],
            [right.bottomAnchor constraintEqualToAnchor:_mediaContainer.bottomAnchor],
            [right.widthAnchor constraintEqualToAnchor:_mediaContainer.widthAnchor multiplier:0.5 constant:-spacing/2],
        ]];
    } else if (count == 3) {
        UIImageView *left = _mediaImageViews[0];
        UIImageView *topRight = _mediaImageViews[1];
        UIImageView *botRight = _mediaImageViews[2];
        [NSLayoutConstraint activateConstraints:@[
            [left.topAnchor constraintEqualToAnchor:_mediaContainer.topAnchor],
            [left.leadingAnchor constraintEqualToAnchor:_mediaContainer.leadingAnchor],
            [left.bottomAnchor constraintEqualToAnchor:_mediaContainer.bottomAnchor],
            [left.widthAnchor constraintEqualToAnchor:_mediaContainer.widthAnchor multiplier:0.5 constant:-spacing/2],

            [topRight.topAnchor constraintEqualToAnchor:_mediaContainer.topAnchor],
            [topRight.trailingAnchor constraintEqualToAnchor:_mediaContainer.trailingAnchor],
            [topRight.widthAnchor constraintEqualToAnchor:_mediaContainer.widthAnchor multiplier:0.5 constant:-spacing/2],
            [topRight.heightAnchor constraintEqualToAnchor:_mediaContainer.heightAnchor multiplier:0.5 constant:-spacing/2],

            [botRight.bottomAnchor constraintEqualToAnchor:_mediaContainer.bottomAnchor],
            [botRight.trailingAnchor constraintEqualToAnchor:_mediaContainer.trailingAnchor],
            [botRight.widthAnchor constraintEqualToAnchor:_mediaContainer.widthAnchor multiplier:0.5 constant:-spacing/2],
            [botRight.heightAnchor constraintEqualToAnchor:_mediaContainer.heightAnchor multiplier:0.5 constant:-spacing/2],
        ]];
    } else {
        UIImageView *topLeft = _mediaImageViews[0];
        UIImageView *topRight = _mediaImageViews[1];
        UIImageView *botLeft = _mediaImageViews[2];
        UIImageView *botRight = _mediaImageViews[3];
        [NSLayoutConstraint activateConstraints:@[
            [topLeft.topAnchor constraintEqualToAnchor:_mediaContainer.topAnchor],
            [topLeft.leadingAnchor constraintEqualToAnchor:_mediaContainer.leadingAnchor],
            [topLeft.widthAnchor constraintEqualToAnchor:_mediaContainer.widthAnchor multiplier:0.5 constant:-spacing/2],
            [topLeft.heightAnchor constraintEqualToAnchor:_mediaContainer.heightAnchor multiplier:0.5 constant:-spacing/2],

            [topRight.topAnchor constraintEqualToAnchor:_mediaContainer.topAnchor],
            [topRight.trailingAnchor constraintEqualToAnchor:_mediaContainer.trailingAnchor],
            [topRight.widthAnchor constraintEqualToAnchor:_mediaContainer.widthAnchor multiplier:0.5 constant:-spacing/2],
            [topRight.heightAnchor constraintEqualToAnchor:_mediaContainer.heightAnchor multiplier:0.5 constant:-spacing/2],

            [botLeft.bottomAnchor constraintEqualToAnchor:_mediaContainer.bottomAnchor],
            [botLeft.leadingAnchor constraintEqualToAnchor:_mediaContainer.leadingAnchor],
            [botLeft.widthAnchor constraintEqualToAnchor:_mediaContainer.widthAnchor multiplier:0.5 constant:-spacing/2],
            [botLeft.heightAnchor constraintEqualToAnchor:_mediaContainer.heightAnchor multiplier:0.5 constant:-spacing/2],

            [botRight.bottomAnchor constraintEqualToAnchor:_mediaContainer.bottomAnchor],
            [botRight.trailingAnchor constraintEqualToAnchor:_mediaContainer.trailingAnchor],
            [botRight.widthAnchor constraintEqualToAnchor:_mediaContainer.widthAnchor multiplier:0.5 constant:-spacing/2],
            [botRight.heightAnchor constraintEqualToAnchor:_mediaContainer.heightAnchor multiplier:0.5 constant:-spacing/2],
        ]];
    }
}

- (void)mediaTapped:(UITapGestureRecognizer *)gesture {
    NSInteger index = gesture.view.tag;
    if (index < (NSInteger)_mediaURLs.count && _statusID.length > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MAMediaTapped"
                                                            object:nil
                                                          userInfo:@{@"statusID": _statusID ?: @"",
                                                                     @"index": @(index)}];
    }
}

- (void)avatarTapped {
    if (_accountID.length > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MAAvatarTapped" object:nil userInfo:@{@"accountID": _accountID}];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _accountID = nil;
    _statusID = nil;
    _mediaURLs = nil;
    _poll = nil;
    _currentStatus = nil;
    _isRevealed = NO;
    _avatarInstance.image = nil;
    _displayNameLabel.text = nil;
    _usernameLabel.text = nil;
    _timestampLabel.text = nil;
    _contentLabel.text = nil;
    _contentLabel.attributedText = nil;
    _contentLabel.hidden = NO;
    _boostLabel.hidden = YES;
    _avatarTopToBoost.active = NO;
    _avatarTopToCard.active = YES;

    _cwLabel.hidden = YES;
    _cwLabel.text = nil;
    _cwButton.hidden = YES;
    [_cwButton setTitle:@"Show content" forState:UIControlStateNormal];
    _contentTopToCWButton.active = NO;
    _contentTopToUsername.active = YES;

    for (UIView *v in _mediaImageViews) [v removeFromSuperview];
    [_mediaImageViews removeAllObjects];
    _mediaContainer.hidden = YES;
    for (NSLayoutConstraint *c in _mediaContainer.constraints) {
        if (c.firstAttribute == NSLayoutAttributeHeight) {
            c.constant = 0;
            break;
        }
    }

    for (UIView *v in _pollOptionViews) [v removeFromSuperview];
    [_pollOptionViews removeAllObjects];
    [_pollOptionButtons removeAllObjects];
    [_selectedPollIndices removeAllObjects];
    _pollContainer.hidden = YES;
    _pollVoteButton.hidden = YES;

    _toolbarTopToMedia.active = YES;
    _toolbarTopToPoll.active = NO;
}

@end
