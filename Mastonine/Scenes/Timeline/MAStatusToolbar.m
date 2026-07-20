#import "MAStatusToolbar.h"
#import "MAAPIClient.h"
#import "MAStatus.h"
#import "MATheme.h"

@implementation MAStatusToolbar

static UIImage *_iconReply = nil;
static UIImage *_iconRepeat = nil;
static UIImage *_iconRepeatFill = nil;
static UIImage *_iconStar = nil;
static UIImage *_iconStarFill = nil;
static UIImage *_iconBookmark = nil;
static UIImage *_iconBookmarkFill = nil;
static UIImage *_iconShare = nil;
static UIImage *_iconEdit = nil;

+ (void)initialize {
    if (self == [MAStatusToolbar class]) {
        _iconReply = [[[self class] loadIcon:@"reply@2x"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _iconRepeat = [[[self class] loadIcon:@"repeat@2x"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _iconRepeatFill = [[[self class] loadIcon:@"repeat-fill@2x"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _iconStar = [[[self class] loadIcon:@"star@2x"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _iconStarFill = [[[self class] loadIcon:@"star-fill@2x"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _iconBookmark = [[[self class] loadIcon:@"bookmark@2x"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _iconBookmarkFill = [[[self class] loadIcon:@"bookmark-fill@2x"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _iconShare = [[[self class] loadIcon:@"share@2x"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _iconEdit = [[[self class] loadIcon:@"edit@2x"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
}

+ (UIImage *)loadIcon:(NSString *)name {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"png" inDirectory:@"Icons"];
    if (!path) path = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
    if (!path) return nil;
    return [UIImage imageWithContentsOfFile:path];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupButtons];
    }
    return self;
}

- (UIImage *)iconNamed:(NSString *)name tinted:(UIColor *)tint {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"png" inDirectory:@"Icons"];
    if (!path) {
        path = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
    }
    if (!path) return nil;
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    if (!img) return nil;
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (UIImage *)iconNamed:(NSString *)name {
    return [self iconNamed:name tinted:nil];
}

- (void)setupButtons {
    _replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _replyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_replyButton setImage:_iconReply forState:UIControlStateNormal];
    [_replyButton setTintColor:[MATheme secondaryTextColor]];
    [_replyButton addTarget:self action:@selector(replyTapped) forControlEvents:UIControlEventTouchUpInside];
    _replyButton.accessibilityLabel = @"Reply";
    [self addSubview:_replyButton];

    _boostButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _boostButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_boostButton setImage:_iconRepeat forState:UIControlStateNormal];
    [_boostButton setTintColor:[MATheme secondaryTextColor]];
    [_boostButton addTarget:self action:@selector(boostTapped) forControlEvents:UIControlEventTouchUpInside];
    _boostButton.accessibilityLabel = @"Boost";
    [self addSubview:_boostButton];

    _favouriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _favouriteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_favouriteButton setImage:_iconStar forState:UIControlStateNormal];
    [_favouriteButton setTintColor:[MATheme secondaryTextColor]];
    [_favouriteButton addTarget:self action:@selector(favouriteTapped) forControlEvents:UIControlEventTouchUpInside];
    _favouriteButton.accessibilityLabel = @"Favourite";
    [self addSubview:_favouriteButton];

    _bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _bookmarkButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_bookmarkButton setImage:_iconBookmark forState:UIControlStateNormal];
    [_bookmarkButton setTintColor:[MATheme secondaryTextColor]];
    [_bookmarkButton addTarget:self action:@selector(bookmarkTapped) forControlEvents:UIControlEventTouchUpInside];
    _bookmarkButton.accessibilityLabel = @"Bookmark";
    [self addSubview:_bookmarkButton];

    _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _shareButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_shareButton setImage:_iconShare forState:UIControlStateNormal];
    [_shareButton setTintColor:[MATheme secondaryTextColor]];
    [_shareButton addTarget:self action:@selector(shareTapped) forControlEvents:UIControlEventTouchUpInside];
    _shareButton.accessibilityLabel = @"Share";
    [self addSubview:_shareButton];

    _editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _editButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_editButton setTitle:@"Edit" forState:UIControlStateNormal];
    [_editButton setTitleColor:[MATheme secondaryTextColor] forState:UIControlStateNormal];
    _editButton.titleLabel.font = [MATheme fontWithSize:13];
    [_editButton addTarget:self action:@selector(editTapped) forControlEvents:UIControlEventTouchUpInside];
    _editButton.accessibilityLabel = @"Edit";
    _editButton.hidden = YES;
    [self addSubview:_editButton];

    CGFloat buttonWidth = 50;

    [NSLayoutConstraint activateConstraints:@[
        [_replyButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8],
        [_replyButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_replyButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [_replyButton.heightAnchor constraintEqualToConstant:40],

        [_boostButton.leadingAnchor constraintEqualToAnchor:_replyButton.trailingAnchor],
        [_boostButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_boostButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [_boostButton.heightAnchor constraintEqualToConstant:40],

        [_favouriteButton.leadingAnchor constraintEqualToAnchor:_boostButton.trailingAnchor],
        [_favouriteButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_favouriteButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [_favouriteButton.heightAnchor constraintEqualToConstant:40],

        [_bookmarkButton.leadingAnchor constraintEqualToAnchor:_favouriteButton.trailingAnchor],
        [_bookmarkButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_bookmarkButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [_bookmarkButton.heightAnchor constraintEqualToConstant:40],

        [_shareButton.trailingAnchor constraintEqualToAnchor:_editButton.leadingAnchor constant:-4],
        [_shareButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_shareButton.widthAnchor constraintEqualToConstant:buttonWidth],
        [_shareButton.heightAnchor constraintEqualToConstant:40],

        [_editButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
        [_editButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    ]];
}

- (void)configureWithReblogCount:(NSInteger)reblogCount
                 favouriteCount:(NSInteger)favouriteCount
                    replyCount:(NSInteger)replyCount
                      reblogged:(BOOL)reblogged
                    favourited:(BOOL)favourited
                      statusID:(NSString *)statusID {
    [self configureWithReblogCount:reblogCount favouriteCount:favouriteCount replyCount:replyCount reblogged:reblogged favourited:favourited bookmarked:NO statusID:statusID];
}

- (void)configureWithReblogCount:(NSInteger)reblogCount
                 favouriteCount:(NSInteger)favouriteCount
                    replyCount:(NSInteger)replyCount
                      reblogged:(BOOL)reblogged
                    favourited:(BOOL)favourited
                     bookmarked:(BOOL)bookmarked
                      statusID:(NSString *)statusID
                    ownAccountID:(NSString *)ownAccountID {
    [self configureWithReblogCount:reblogCount favouriteCount:favouriteCount replyCount:replyCount reblogged:reblogged favourited:favourited bookmarked:bookmarked statusID:statusID];

    _ownAccountID = ownAccountID;
    _editButton.hidden = (ownAccountID.length == 0);
}

- (void)configureWithReblogCount:(NSInteger)reblogCount
                 favouriteCount:(NSInteger)favouriteCount
                    replyCount:(NSInteger)replyCount
                      reblogged:(BOOL)reblogged
                    favourited:(BOOL)favourited
                     bookmarked:(BOOL)bookmarked
                      statusID:(NSString *)statusID {

    _statusID = statusID;
    _isReblogged = reblogged;
    _isFavourited = favourited;
    _isBookmarked = bookmarked;

    // Reply - always same tint
    [_replyButton setTintColor:[MATheme secondaryTextColor]];

    // Boost
    if (reblogged) {
        [_boostButton setImage:_iconRepeatFill forState:UIControlStateNormal];
        [_boostButton setTintColor:[MATheme boostColor]];
    } else {
        [_boostButton setImage:_iconRepeat forState:UIControlStateNormal];
        [_boostButton setTintColor:[MATheme secondaryTextColor]];
    }
    _boostButton.accessibilityLabel = reblogged ? @"Unboost" : @"Boost";

    // Favourite
    if (favourited) {
        [_favouriteButton setImage:_iconStarFill forState:UIControlStateNormal];
        [_favouriteButton setTintColor:[MATheme favoriteColor]];
    } else {
        [_favouriteButton setImage:_iconStar forState:UIControlStateNormal];
        [_favouriteButton setTintColor:[MATheme secondaryTextColor]];
    }
    _favouriteButton.accessibilityLabel = favourited ? @"Unfavourite" : @"Favourite";

    // Bookmark
    if (bookmarked) {
        [_bookmarkButton setImage:_iconBookmarkFill forState:UIControlStateNormal];
        [_bookmarkButton setTintColor:[MATheme primaryColor]];
    } else {
        [_bookmarkButton setImage:_iconBookmark forState:UIControlStateNormal];
        [_bookmarkButton setTintColor:[MATheme secondaryTextColor]];
    }
    _bookmarkButton.accessibilityLabel = bookmarked ? @"Remove Bookmark" : @"Bookmark";

    // Share
    [_shareButton setTintColor:[MATheme secondaryTextColor]];
}

- (void)replyTapped {
    if (!_statusID) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusReply" object:nil userInfo:@{@"statusID": _statusID}];
}

- (void)boostTapped {
    if (!_statusID) return;
    if (_isReblogged) {
        [[MAAPIClient sharedClient] unboostStatus:_statusID completion:^(MAStatus *status, NSError *error) {
            if (!error && status) {
                self.isReblogged = status.reblogged;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusUpdated" object:nil userInfo:@{@"status": status}];
            }
        }];
    } else {
        [[MAAPIClient sharedClient] boostStatus:_statusID completion:^(MAStatus *status, NSError *error) {
            if (!error && status) {
                self.isReblogged = status.reblogged;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusUpdated" object:nil userInfo:@{@"status": status}];
            }
        }];
    }
}

- (void)favouriteTapped {
    if (!_statusID) return;
    if (_isFavourited) {
        [[MAAPIClient sharedClient] unfavouriteStatus:_statusID completion:^(MAStatus *status, NSError *error) {
            if (!error && status) {
                self.isFavourited = status.favourited;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusUpdated" object:nil userInfo:@{@"status": status}];
            }
        }];
    } else {
        [[MAAPIClient sharedClient] favouriteStatus:_statusID completion:^(MAStatus *status, NSError *error) {
            if (!error && status) {
                self.isFavourited = status.favourited;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusUpdated" object:nil userInfo:@{@"status": status}];
            }
        }];
    }
}

- (void)bookmarkTapped {
    if (!_statusID) return;
    if (_isBookmarked) {
        [[MAAPIClient sharedClient] unbookmarkStatus:_statusID completion:^(MAStatus *status, NSError *error) {
            if (!error && status) {
                self.isBookmarked = status.bookmarked;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusUpdated" object:nil userInfo:@{@"status": status}];
            }
        }];
    } else {
        [[MAAPIClient sharedClient] bookmarkStatus:_statusID completion:^(MAStatus *status, NSError *error) {
            if (!error && status) {
                self.isBookmarked = status.bookmarked;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusUpdated" object:nil userInfo:@{@"status": status}];
            }
        }];
    }
}

- (void)shareTapped {
    if (!_statusID) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusShare" object:nil userInfo:@{@"statusID": _statusID}];
}

- (void)editTapped {
    if (!_statusID) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusEdit" object:nil userInfo:@{@"statusID": _statusID}];
}

@end
