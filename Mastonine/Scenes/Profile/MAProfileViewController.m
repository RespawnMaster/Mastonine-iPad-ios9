#import "MAProfileViewController.h"
#import "MAStatusTableViewCell.h"
#import "MAAPIClient.h"
#import "MAAccount.h"
#import "MAStatus.h"
#import "MAImageCache.h"
#import "MAAvatarView.h"
#import "MATheme.h"
#import "MAHTMLRenderer.h"
#import "MAThreadViewController.h"
#import "MAAccountListViewController.h"
#import "MAProfileEditViewController.h"
#import "MASpotlightIndexer.h"

static const CGFloat kHeaderHeight = 180;
static const CGFloat kAvatarSize = 80;
static const CGFloat kProfileInfoHeight = 120;

@interface MAProfileViewController ()
@property (nonatomic, strong) MAAvatarView *avatarInstance;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) NSDictionary *relationship;
@property (nonatomic, strong) UIButton *postsButton;
@property (nonatomic, strong) UIButton *followingButton;
@property (nonatomic, strong) UIButton *followersButton;
@property (nonatomic, strong) UIView *fieldsContainer;
@property (nonatomic, strong) UIView *featuredTagsContainer;
@property (nonatomic, strong) UIView *domainContainer;
@property (nonatomic, assign) CGFloat domainY;
@property (nonatomic, assign) CGFloat bioBaseY;
@end

@implementation MAProfileViewController

- (instancetype)initWithAccountID:(NSString *)accountID {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _accountID = accountID;
        _statuses = @[];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    return [self initWithAccountID:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [MATheme backgroundColor];
    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [self.tableView registerClass:[MAStatusTableViewCell class] forCellReuseIdentifier:@"StatusCell"];

    if (_accountID) {
        self.title = @"Profile";
    } else {
        self.title = @"My Profile";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                                                   style:UIBarButtonItemStylePlain
                                                                                  target:self
                                                                                  action:@selector(editTapped)];
    }

    [self setupTableHeader];
    [self loadProfile];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_accountID) {
        [self reloadRelationship];
    }
}

- (void)setupTableHeader {
    CGFloat w = self.view.frame.size.width;
    CGFloat headerContentHeight = kHeaderHeight + kAvatarSize/2 + kProfileInfoHeight;
    if (_accountID) {
        headerContentHeight += 52;
    }

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, headerContentHeight)];

    _headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, w, kHeaderHeight)];
    _headerImageView.contentMode = UIViewContentModeScaleAspectFill;
    _headerImageView.clipsToBounds = YES;
    _headerImageView.backgroundColor = [MATheme primaryDarkColor];

    UIView *headerOverlay = [[UIView alloc] initWithFrame:_headerImageView.bounds];
    headerOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    [_headerImageView addSubview:headerOverlay];
    [headerView addSubview:_headerImageView];

    CGFloat centerX = w / 2;

    _avatarInstance = [[MAAvatarView alloc] initWithFrame:CGRectMake(centerX - kAvatarSize/2, kHeaderHeight - kAvatarSize/2, kAvatarSize, kAvatarSize)];
    _avatarInstance.borderWidth = 4;
    _avatarInstance.borderColor = [MATheme cardColor];
    _profileAvatar = _avatarInstance;
    [headerView addSubview:_avatarInstance];

    CGFloat y = kHeaderHeight + kAvatarSize/2 + 8;

    _displayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, y, w - 32, 24)];
    _displayNameLabel.font = [MATheme boldFontWithSize:20];
    _displayNameLabel.textColor = [MATheme textColor];
    _displayNameLabel.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:_displayNameLabel];
    y += 26;

    _usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, y, w - 32, 20)];
    _usernameLabel.font = [MATheme fontWithSize:14];
    _usernameLabel.textColor = [MATheme secondaryTextColor];
    _usernameLabel.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:_usernameLabel];
    y += 22;

    _domainContainer = [[UIView alloc] initWithFrame:CGRectMake(16, y, w - 32, 20)];
    _domainContainer.hidden = YES;
    [headerView addSubview:_domainContainer];
    _domainY = y;
    y += 24;

    CGFloat statsY = y;
    CGFloat statsW = w;
    CGFloat btnW = statsW / 3.0;

    _postsButton = [self statButtonWithTitle:@"0 posts" atX:0 width:btnW atY:statsY action:@selector(postsTapped)];
    [headerView addSubview:_postsButton];

    _followingButton = [self statButtonWithTitle:@"0 following" atX:btnW width:btnW atY:statsY action:@selector(followingTapped)];
    [headerView addSubview:_followingButton];

    _followersButton = [self statButtonWithTitle:@"0 followers" atX:btnW * 2 width:btnW atY:statsY action:@selector(followersTapped)];
    [headerView addSubview:_followersButton];
    y += 30;

    _statsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statsLabel.hidden = YES;
    [headerView addSubview:_statsLabel];

    _statsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statsLabel.hidden = YES;
    [headerView addSubview:_statsLabel];

    _bioLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _bioLabel.font = [MATheme fontWithSize:13];
    _bioLabel.textColor = [MATheme textColor];
    _bioLabel.numberOfLines = 0;
    _bioLabel.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:_bioLabel];

    _fieldsContainer = [[UIView alloc] initWithFrame:CGRectZero];
    [headerView addSubview:_fieldsContainer];

    _featuredTagsContainer = [[UIView alloc] initWithFrame:CGRectZero];
    [headerView addSubview:_featuredTagsContainer];

    if (_accountID) {
        _followButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _followButton.translatesAutoresizingMaskIntoConstraints = YES;
        _followButton.titleLabel.font = [MATheme boldFontWithSize:14];
        _followButton.layer.cornerRadius = 16;
        _followButton.layer.borderWidth = 1.5;
        [_followButton addTarget:self action:@selector(followTapped) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:_followButton];

        _followButton.frame = CGRectMake(centerX - 80, statsY + 34, 160, 32);

        _bioLabel.frame = CGRectMake(32, statsY + 78, w - 64, 80);
    } else {
        _bioLabel.frame = CGRectMake(32, statsY + 34, w - 64, 80);
    }
    _bioBaseY = _bioLabel.frame.origin.y;
    _fieldsContainer.frame = CGRectMake(16, _bioBaseY + 88, w - 32, 0);

    self.tableView.tableHeaderView = headerView;
}

- (UIButton *)statButtonWithTitle:(NSString *)title atX:(CGFloat)x width:(CGFloat)w atY:(CGFloat)y action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(x, y, w, 24);
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[MATheme textColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [MATheme boldFontWithSize:13];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    btn.titleLabel.textAlignment = NSTextAlignmentCenter;
    return btn;
}

- (void)postsTapped {
}

- (void)editTapped {
    MAProfileEditViewController *editVC = [[MAProfileEditViewController alloc] init];
    [self.navigationController pushViewController:editVC animated:YES];
}

- (void)followingTapped {
    if (!_accountID) return;
    MAAccountListViewController *list = [[MAAccountListViewController alloc] initWithAccountID:_accountID followers:NO];
    [self.navigationController pushViewController:list animated:YES];
}

- (void)followersTapped {
    if (!_accountID) return;
    MAAccountListViewController *list = [[MAAccountListViewController alloc] initWithAccountID:_accountID followers:YES];
    [self.navigationController pushViewController:list animated:YES];
}

- (void)updateFollowButton {
    if (!_followButton) return;

    BOOL isFollowing = [_relationship[@"following"] boolValue];
    BOOL isRequested = [_relationship[@"requested"] boolValue];
    BOOL isBlocked = [_relationship[@"blocking"] boolValue];
    BOOL isMuted = [_relationship[@"muting"] boolValue];

    if (isBlocked) {
        [_followButton setTitle:@"Blocked" forState:UIControlStateNormal];
        [_followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _followButton.backgroundColor = [MATheme dangerColor];
        _followButton.layer.borderColor = [MATheme dangerColor].CGColor;
    } else if (isMuted) {
        [_followButton setTitle:@"Muted" forState:UIControlStateNormal];
        [_followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _followButton.backgroundColor = [MATheme secondaryTextColor];
        _followButton.layer.borderColor = [MATheme secondaryTextColor].CGColor;
    } else if (isRequested) {
        [_followButton setTitle:@"Requested" forState:UIControlStateNormal];
        [_followButton setTitleColor:[MATheme secondaryTextColor] forState:UIControlStateNormal];
        _followButton.backgroundColor = [UIColor clearColor];
        _followButton.layer.borderColor = [MATheme secondaryTextColor].CGColor;
    } else if (isFollowing) {
        [_followButton setTitle:@"Following" forState:UIControlStateNormal];
        [_followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _followButton.backgroundColor = [MATheme primaryColor];
        _followButton.layer.borderColor = [MATheme primaryColor].CGColor;
    } else {
        [_followButton setTitle:@"Follow" forState:UIControlStateNormal];
        [_followButton setTitleColor:[MATheme primaryColor] forState:UIControlStateNormal];
        _followButton.backgroundColor = [UIColor clearColor];
        _followButton.layer.borderColor = [MATheme primaryColor].CGColor;
    }
}

#pragma mark - Fields / Metadata

- (void)updateFields {
    for (UIView *subview in _fieldsContainer.subviews) {
        [subview removeFromSuperview];
    }

    if (_account.fields.count == 0) {
        _fieldsContainer.hidden = YES;
        return;
    }

    _fieldsContainer.hidden = NO;
    CGFloat width = _fieldsContainer.frame.size.width;
    CGFloat y = 0;

    for (NSDictionary *field in _account.fields) {
        NSString *name = field[@"name"] ?: @"";
        NSString *value = field[@"value"] ?: @"";

        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, width, 18)];
        nameLabel.font = [MATheme boldFontWithSize:12];
        nameLabel.textColor = [MATheme secondaryTextColor];
        nameLabel.text = [name uppercaseString];
        [_fieldsContainer addSubview:nameLabel];
        y += 18;

        NSAttributedString *renderedValue = [MAHTMLRenderer renderHTML:value withFontSize:13.0 color:[MATheme textColor]];

        UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, width, 0)];
        valueLabel.numberOfLines = 0;
        valueLabel.attributedText = renderedValue;
        [valueLabel sizeToFit];
        valueLabel.frame = CGRectMake(0, y, width, valueLabel.frame.size.height);
        [_fieldsContainer addSubview:valueLabel];
        y += valueLabel.frame.size.height + 10;
    }

    _fieldsContainer.frame = CGRectMake(_fieldsContainer.frame.origin.x, _fieldsContainer.frame.origin.y, width, y);
}

- (void)updateFeaturedTags {
    for (UIView *subview in _featuredTagsContainer.subviews) {
        [subview removeFromSuperview];
    }

    if (_account.featuredTags.count == 0) {
        _featuredTagsContainer.hidden = YES;
        return;
    }

    _featuredTagsContainer.hidden = NO;
    CGFloat containerWidth = self.view.frame.size.width - 32;
    CGFloat x = 0;
    CGFloat y = 0;

    UILabel *sectionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, containerWidth, 18)];
    sectionLabel.font = [MATheme boldFontWithSize:12];
    sectionLabel.textColor = [MATheme secondaryTextColor];
    sectionLabel.text = @"FEATURED TAGS";
    [_featuredTagsContainer addSubview:sectionLabel];
    y = 22;

    for (NSString *tagName in _account.featuredTags) {
        NSString *labelText = [NSString stringWithFormat:@"#%@", tagName];
        CGSize size = [labelText sizeWithAttributes:@{NSFontAttributeName: [MATheme boldFontWithSize:13]}];

        if (x + size.width + 20 > containerWidth) {
            x = 0;
            y += 30;
        }

        UIButton *tagButton = [UIButton buttonWithType:UIButtonTypeSystem];
        tagButton.frame = CGRectMake(x, y, size.width + 16, 26);
        tagButton.backgroundColor = [MATheme primaryColor];
        tagButton.layer.cornerRadius = 13;
        [tagButton setTitle:labelText forState:UIControlStateNormal];
        [tagButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        tagButton.titleLabel.font = [MATheme boldFontWithSize:13];
        [_featuredTagsContainer addSubview:tagButton];
        x += size.width + 24;
    }

    CGFloat fieldsMaxY = CGRectGetMaxY(_fieldsContainer.frame);
    _featuredTagsContainer.frame = CGRectMake(16, fieldsMaxY > 0 ? fieldsMaxY + 8 : _bioLabel.frame.origin.y + _bioLabel.frame.size.height + 8, containerWidth, y + 30);
}

- (void)updateDomain {
    for (UIView *subview in _domainContainer.subviews) {
        [subview removeFromSuperview];
    }

    CGFloat w = self.view.frame.size.width - 32;
    CGFloat domainHeight = 0;

    if (_account.domain.length == 0) {
        _domainContainer.hidden = YES;
    } else {
        _domainContainer.hidden = NO;
        domainHeight = 20;

        UILabel *domainLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, w, 20)];
        domainLabel.font = [MATheme fontWithSize:12];
        domainLabel.textColor = [MATheme secondaryTextColor];
        domainLabel.textAlignment = NSTextAlignmentCenter;
        domainLabel.text = [NSString stringWithFormat:@"Joined from %@", _account.domain];
        [_domainContainer addSubview:domainLabel];
    }

    CGFloat shift = domainHeight;
    CGFloat statsY = _domainY + shift;
    CGFloat btnW = self.view.frame.size.width / 3.0;

    _postsButton.frame = CGRectMake(0, statsY, btnW, 24);
    _followingButton.frame = CGRectMake(btnW, statsY, btnW, 24);
    _followersButton.frame = CGRectMake(btnW * 2, statsY, btnW, 24);

    if (_followButton) {
        _followButton.frame = CGRectMake(self.view.frame.size.width / 2 - 80, statsY + 34, 160, 32);
    }

    CGFloat bioY = statsY + (_followButton ? 78 : 34);
    _bioLabel.frame = CGRectMake(32, bioY, self.view.frame.size.width - 64, _bioLabel.frame.size.height);
    _fieldsContainer.frame = CGRectMake(16, CGRectGetMaxY(_bioLabel.frame) + 8, self.view.frame.size.width - 32, _fieldsContainer.frame.size.height);
}

#pragma mark - Header Resize

- (void)resizeHeader {
    UIView *headerView = self.tableView.tableHeaderView;

    CGFloat bottomY = CGRectGetMaxY(_domainContainer.frame) + 12;

    if (_account.featuredTags.count > 0 && !_featuredTagsContainer.hidden) {
        bottomY = MAX(bottomY, CGRectGetMaxY(_featuredTagsContainer.frame) + 12);
    }
    if (_account.fields.count > 0 && !_fieldsContainer.hidden) {
        bottomY = MAX(bottomY, CGRectGetMaxY(_fieldsContainer.frame) + 12);
    }

    bottomY = MAX(bottomY, CGRectGetMaxY(_bioLabel.frame) + 12);

    if (_followButton) {
        bottomY = MAX(bottomY, CGRectGetMaxY(_followButton.frame) + 12);
    }

    headerView.frame = CGRectMake(0, 0, self.view.frame.size.width, bottomY);
    self.tableView.tableHeaderView = headerView;
}

#pragma mark - Follow

- (void)followTapped {
    if (!_accountID) return;

    BOOL isFollowing = [_relationship[@"following"] boolValue];
    BOOL isBlocked = [_relationship[@"blocking"] boolValue];
    BOOL isMuted = [_relationship[@"muting"] boolValue];
    BOOL isRequested = [_relationship[@"requested"] boolValue];

    if (isBlocked) {
        UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Blocked"
                                                                       message:@"This account is blocked."
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Unblock" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [[MAAPIClient sharedClient] unblockAccount:self->_accountID completion:^(MAAccount *account, NSError *error) {
                if (!error) [self reloadRelationship];
            }];
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            [self reportUser];
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:sheet animated:YES completion:nil];
        return;
    }

    if (isMuted) {
        UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Muted"
                                                                       message:@"This account is muted."
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Unmute" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [[MAAPIClient sharedClient] unmuteAccount:self->_accountID completion:^(MAAccount *account, NSError *error) {
                if (!error) [self reloadRelationship];
            }];
        }]];
        if (!isFollowing) {
            [sheet addAction:[UIAlertAction actionWithTitle:@"Follow" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                [[MAAPIClient sharedClient] followAccount:self->_accountID completion:^(MAAccount *account, NSError *error) {
                    if (!error) [self reloadRelationship];
                }];
            }]];
        }
        [sheet addAction:[UIAlertAction actionWithTitle:@"Unfollow" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            [[MAAPIClient sharedClient] unfollowAccount:self->_accountID completion:^(MAAccount *account, NSError *error) {
                if (!error) [self reloadRelationship];
            }];
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Block" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            [[MAAPIClient sharedClient] blockAccount:self->_accountID completion:^(MAAccount *account, NSError *error) {
                if (!error) [self reloadRelationship];
            }];
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            [self reportUser];
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:sheet animated:YES completion:nil];
        return;
    }

    if (isFollowing) {
        UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Unfollow" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            [[MAAPIClient sharedClient] unfollowAccount:self->_accountID completion:^(MAAccount *account, NSError *error) {
                if (!error) [self reloadRelationship];
            }];
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Mute" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [[MAAPIClient sharedClient] muteAccount:self->_accountID completion:^(MAAccount *account, NSError *error) {
                if (!error) [self reloadRelationship];
            }];
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Block" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [[MAAPIClient sharedClient] blockAccount:self->_accountID completion:^(MAAccount *account, NSError *error) {
                if (!error) [self reloadRelationship];
            }];
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            [self reportUser];
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:sheet animated:YES completion:nil];
        return;
    }

    if (isRequested) {
        UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Follow Requested"
                                                                       message:@"Awaiting approval."
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel Request" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            [[MAAPIClient sharedClient] unfollowAccount:self->_accountID completion:^(MAAccount *account, NSError *error) {
                if (!error) [self reloadRelationship];
            }];
        }]];
        [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:sheet animated:YES completion:nil];
        return;
    }

    [[MAAPIClient sharedClient] followAccount:_accountID completion:^(MAAccount *account, NSError *error) {
        if (!error) [self reloadRelationship];
    }];
}

- (void)reportUser {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Report"
                                                                  message:@"Why are you reporting this account?"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"Reason (optional)";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        NSString *reason = alert.textFields.firstObject.text ?: @"";
        [[MAAPIClient sharedClient] reportAccount:self->_accountID statusIDs:nil reason:reason completion:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *msg = error ? @"Failed to report." : @"Reported.";
                UIAlertController *done = [UIAlertController alertControllerWithTitle:@"Report"
                                                                             message:msg
                                                                      preferredStyle:UIAlertControllerStyleAlert];
                [done addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:done animated:YES completion:nil];
            });
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Data Loading

- (void)loadProfile {
    if (_accountID) {
        [[MAAPIClient sharedClient] fetchAccountByID:_accountID completion:^(MAAccount *account, NSError *error) {
            if (account) {
                self->_account = account;
                [self updateProfileUI];
                [self loadStatuses];
                [self reloadRelationship];
            }
        }];
    } else {
        [[MAAPIClient sharedClient] verifyCredentialsWithCompletion:^(MAAccount *account, NSError *error) {
            if (account) {
                self->_account = account;
                [self updateProfileUI];
                self->_accountID = account.accountID;
                [self loadStatuses];
            }
        }];
    }
}

- (void)reloadRelationship {
    if (!_accountID) return;
    [[MAAPIClient sharedClient] fetchRelationshipForAccount:_accountID completion:^(NSDictionary *relationship, NSError *error) {
        if (relationship) {
            self->_relationship = relationship;
            [self updateFollowButton];
        }
    }];
}

- (void)updateProfileUI {
    if (!_account) return;
    self.title = [_account displayNameOrUsername];
    _displayNameLabel.text = [_account displayNameOrUsername];
    _usernameLabel.text = [NSString stringWithFormat:@"@%@", _account.username];

    [_postsButton setTitle:[NSString stringWithFormat:@"%ld posts", (long)_account.statusesCount] forState:UIControlStateNormal];
    [_followingButton setTitle:[NSString stringWithFormat:@"%ld following", (long)_account.followingCount] forState:UIControlStateNormal];
    [_followersButton setTitle:[NSString stringWithFormat:@"%ld followers", (long)_account.followersCount] forState:UIControlStateNormal];

    NSAttributedString *bio = [MAHTMLRenderer renderHTML:_account.note withFontSize:13.0 color:[MATheme textColor]];
    _bioLabel.attributedText = bio;

    CGFloat w = self.view.frame.size.width - 64;
    CGSize maxSize = CGSizeMake(w, CGFLOAT_MAX);
    CGSize bioSize = [_bioLabel sizeThatFits:maxSize];
    CGFloat bioHeight = MAX(bioSize.height, 20);
    CGFloat bioY = _bioLabel.frame.origin.y;
    _bioLabel.frame = CGRectMake(32, bioY, w, bioHeight);

    CGFloat fieldsY = bioY + bioHeight + 8;
    _fieldsContainer.frame = CGRectMake(16, fieldsY, self.view.frame.size.width - 32, _fieldsContainer.frame.size.height);

    [_avatarInstance configureWithAvatarURL:[_account avatarURL]];
    [_headerImageView setImage:nil];

    NSURL *headerURL = [_account headerURL];
    if (headerURL) {
        [[MAImageCache sharedCache] fetchImageAtURL:headerURL completion:^(UIImage *image) {
            if (image) {
                self->_headerImageView.image = image;
            }
        }];
    }

    [self updateFields];
    [self updateFeaturedTags];
    [self updateDomain];
    [self resizeHeader];
}

- (void)loadStatuses {
    if (_isLoading || !_accountID) return;
    _isLoading = YES;

    [[MAAPIClient sharedClient] fetchAccount:_accountID statusesMaxID:_maxID completion:^(NSArray *statuses, NSError *error) {
        self->_isLoading = NO;
        if (error || statuses.count == 0) return;

        if (self->_maxID) {
            NSMutableArray *newStatuses = [self->_statuses mutableCopy];
            [newStatuses addObjectsFromArray:statuses];
            self->_statuses = newStatuses;
        } else {
            self->_statuses = statuses;
        }

        if (statuses.count > 0) {
            MAStatus *last = statuses.lastObject;
            self->_maxID = last.statusID;
        }

        [self.tableView reloadData];

        [MASpotlightIndexer indexAccount:self->_account];
        for (MAStatus *s in self->_statuses) {
            [MASpotlightIndexer indexStatus:s];
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _statuses.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MAStatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StatusCell" forIndexPath:indexPath];
    MAStatus *status = _statuses[indexPath.row];
    [cell configureWithStatus:status];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (NSInteger)_statuses.count - 5) {
        [self loadStatuses];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MAStatus *status = _statuses[indexPath.row];
    MAThreadViewController *thread = [[MAThreadViewController alloc] initWithStatusID:status.statusID];
    [self.navigationController pushViewController:thread animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 200;
}

@end
