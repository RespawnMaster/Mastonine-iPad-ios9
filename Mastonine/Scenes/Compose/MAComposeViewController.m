#import "MAComposeViewController.h"
#import "MAAPIClient.h"
#import "MATheme.h"
#import "MADraftManager.h"

@interface MAComposeViewController () <UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *characterCountLabel;
@property (nonatomic, strong) UIButton *visibilityButton;
@property (nonatomic, strong) UIButton *languageButton;
@property (nonatomic, strong) NSString *currentVisibility;
@property (nonatomic, strong) NSString *currentLanguage;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, assign) NSInteger maxCharacters;

@property (nonatomic, strong) UIButton *pollToggleButton;
@property (nonatomic, assign) BOOL pollEnabled;
@property (nonatomic, strong) UIView *pollOptionsContainer;
@property (nonatomic, strong) NSMutableArray *pollOptionTextFields;
@property (nonatomic, strong) UIButton *addPollOptionButton;
@property (nonatomic, strong) UIButton *removePollOptionButton;
@property (nonatomic, strong) UISegmentedControl *pollDurationControl;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSLayoutConstraint *pollContainerBottom;

@property (nonatomic, strong) UIButton *addMediaButton;
@property (nonatomic, strong) UIScrollView *mediaPreviewScrollView;
@property (nonatomic, strong) NSMutableArray *mediaAttachments;
@property (nonatomic, strong) NSMutableArray *mediaPreviewViews;
@property (nonatomic, assign) BOOL isPosting;

@end

@implementation MAComposeViewController

- (instancetype)initWithReplyToStatusID:(NSString *)statusID username:(NSString *)username {
    self = [super init];
    if (self) {
        _replyToStatusID = statusID;
        _replyToUsername = username;
        _currentVisibility = @"public";
        _currentLanguage = @"";
        _maxCharacters = 500;
        _pollEnabled = NO;
        _mediaAttachments = [NSMutableArray array];
        _mediaPreviewViews = [NSMutableArray array];
    }
    return self;
}

- (instancetype)init {
    return [self initWithReplyToStatusID:nil username:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [MATheme backgroundColor];

    if (_editStatusID) {
        self.title = @"Edit Post";
    } else if (_replyToUsername) {
        self.title = [NSString stringWithFormat:@"Reply to @%@", _replyToUsername];
    } else {
        self.title = @"New Toot";
    }

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancelTapped)];

    if (_editStatusID) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(saveEditTapped)];
    } else {
        UIBarButtonItem *draftBtn = [[UIBarButtonItem alloc] initWithTitle:@"Draft"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(saveDraftTapped)];
        UIBarButtonItem *postBtn = [[UIBarButtonItem alloc] initWithTitle:@"Toot"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(postTapped)];
        self.navigationItem.rightBarButtonItems = @[postBtn, draftBtn];
    }

    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:_scrollView];

    _textView = [[UITextView alloc] initWithFrame:CGRectZero];
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    _textView.backgroundColor = [MATheme cardColor];
    _textView.textColor = [MATheme textColor];
    _textView.font = [MATheme fontWithSize:17];
    _textView.layer.cornerRadius = 10;
    _textView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12);
    _textView.autocorrectionType = UITextAutocorrectionTypeYes;
    _textView.keyboardAppearance = [MATheme isDarkMode] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    _textView.delegate = (id)self;
    [_scrollView addSubview:_textView];

    _characterCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _characterCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _characterCountLabel.font = [MATheme fontWithSize:13];
    _characterCountLabel.textColor = [MATheme secondaryTextColor];
    _characterCountLabel.textAlignment = NSTextAlignmentRight;
    [_scrollView addSubview:_characterCountLabel];

    _visibilityButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _visibilityButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_visibilityButton setTitle:@"Public \u25BC" forState:UIControlStateNormal];
    [_visibilityButton setTitleColor:[MATheme primaryColor] forState:UIControlStateNormal];
    _visibilityButton.titleLabel.font = [MATheme fontWithSize:14];
    [_visibilityButton addTarget:self action:@selector(visibilityTapped) forControlEvents:UIControlEventTouchUpInside];
    _visibilityButton.accessibilityLabel = @"Change visibility";
    [_scrollView addSubview:_visibilityButton];

    _languageButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _languageButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_languageButton setTitle:@"Language" forState:UIControlStateNormal];
    [_languageButton setTitleColor:[MATheme primaryColor] forState:UIControlStateNormal];
    _languageButton.titleLabel.font = [MATheme fontWithSize:14];
    [_languageButton addTarget:self action:@selector(languageTapped) forControlEvents:UIControlEventTouchUpInside];
    _languageButton.accessibilityLabel = @"Change language";
    [_scrollView addSubview:_languageButton];

    _addMediaButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _addMediaButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_addMediaButton setTitle:@"Add Media" forState:UIControlStateNormal];
    [_addMediaButton setTitleColor:[MATheme primaryColor] forState:UIControlStateNormal];
    [_addMediaButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    _addMediaButton.titleLabel.font = [MATheme boldFontWithSize:14];
    _addMediaButton.backgroundColor = [MATheme cardColor];
    _addMediaButton.layer.cornerRadius = 6;
    _addMediaButton.layer.borderWidth = 1;
    _addMediaButton.layer.borderColor = [MATheme primaryColor].CGColor;
    _addMediaButton.contentEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 16);
    [_addMediaButton addTarget:self action:@selector(addMediaTapped) forControlEvents:UIControlEventTouchUpInside];
    _addMediaButton.accessibilityLabel = @"Add media attachment";
    [_scrollView addSubview:_addMediaButton];

    _mediaPreviewScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _mediaPreviewScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _mediaPreviewScrollView.showsHorizontalScrollIndicator = NO;
    _mediaPreviewScrollView.hidden = YES;
    [_scrollView addSubview:_mediaPreviewScrollView];

    _pollToggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _pollToggleButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_pollToggleButton setTitle:@"Poll: Off" forState:UIControlStateNormal];
    [_pollToggleButton setTitleColor:[MATheme primaryColor] forState:UIControlStateNormal];
    _pollToggleButton.titleLabel.font = [MATheme fontWithSize:14];
    [_pollToggleButton addTarget:self action:@selector(pollToggleTapped) forControlEvents:UIControlEventTouchUpInside];
    _pollToggleButton.accessibilityLabel = @"Toggle poll";
    [_scrollView addSubview:_pollToggleButton];

    _pollOptionsContainer = [[UIView alloc] init];
    _pollOptionsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _pollOptionsContainer.hidden = YES;
    [_scrollView addSubview:_pollOptionsContainer];

    _pollOptionTextFields = [NSMutableArray array];

    _addPollOptionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _addPollOptionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_addPollOptionButton setTitle:@"+ Add Option" forState:UIControlStateNormal];
    [_addPollOptionButton setTitleColor:[MATheme primaryColor] forState:UIControlStateNormal];
    _addPollOptionButton.titleLabel.font = [MATheme fontWithSize:14];
    _addPollOptionButton.hidden = YES;
    [_addPollOptionButton addTarget:self action:@selector(addPollOptionTapped) forControlEvents:UIControlEventTouchUpInside];
    _addPollOptionButton.accessibilityLabel = @"Add poll option";
    [_scrollView addSubview:_addPollOptionButton];

    _removePollOptionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _removePollOptionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_removePollOptionButton setTitle:@"- Remove Option" forState:UIControlStateNormal];
    [_removePollOptionButton setTitleColor:[MATheme dangerColor] forState:UIControlStateNormal];
    _removePollOptionButton.titleLabel.font = [MATheme fontWithSize:14];
    _removePollOptionButton.hidden = YES;
    [_removePollOptionButton addTarget:self action:@selector(removePollOptionTapped) forControlEvents:UIControlEventTouchUpInside];
    _removePollOptionButton.accessibilityLabel = @"Remove poll option";
    [_scrollView addSubview:_removePollOptionButton];

    NSArray *durations = @[@"1 hour", @"6 hours", @"12 hours", @"1 day", @"3 days", @"7 days"];
    _pollDurationControl = [[UISegmentedControl alloc] initWithItems:durations];
    _pollDurationControl.translatesAutoresizingMaskIntoConstraints = NO;
    _pollDurationControl.selectedSegmentIndex = 0;
    _pollDurationControl.hidden = YES;
    [_scrollView addSubview:_pollDurationControl];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _spinner.translatesAutoresizingMaskIntoConstraints = NO;
    _spinner.color = [MATheme primaryColor];
    _spinner.hidesWhenStopped = YES;
    [_scrollView addSubview:_spinner];

    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:64],
        [_scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [_textView.topAnchor constraintEqualToAnchor:_scrollView.topAnchor constant:12],
        [_textView.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor constant:16],
        [_textView.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor constant:-16],
        [_textView.widthAnchor constraintEqualToAnchor:_scrollView.widthAnchor constant:-32],
        [_textView.heightAnchor constraintEqualToConstant:180],

        [_characterCountLabel.topAnchor constraintEqualToAnchor:_textView.bottomAnchor constant:8],
        [_characterCountLabel.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor constant:-16],

        [_visibilityButton.topAnchor constraintEqualToAnchor:_textView.bottomAnchor constant:8],
        [_visibilityButton.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor constant:16],

        [_languageButton.topAnchor constraintEqualToAnchor:_textView.bottomAnchor constant:8],
        [_languageButton.leadingAnchor constraintEqualToAnchor:_visibilityButton.trailingAnchor constant:16],

        [_addMediaButton.topAnchor constraintEqualToAnchor:_characterCountLabel.bottomAnchor constant:16],
        [_addMediaButton.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor constant:16],
        [_addMediaButton.heightAnchor constraintEqualToConstant:36],

        [_mediaPreviewScrollView.topAnchor constraintEqualToAnchor:_addMediaButton.bottomAnchor constant:10],
        [_mediaPreviewScrollView.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor constant:16],
        [_mediaPreviewScrollView.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor constant:-16],
        [_mediaPreviewScrollView.heightAnchor constraintEqualToConstant:80],

        [_pollToggleButton.topAnchor constraintEqualToAnchor:_mediaPreviewScrollView.bottomAnchor constant:12],
        [_pollToggleButton.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor constant:16],

        [_pollOptionsContainer.topAnchor constraintEqualToAnchor:_pollToggleButton.bottomAnchor constant:10],
        [_pollOptionsContainer.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor constant:16],
        [_pollOptionsContainer.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor constant:-16],
        [_pollOptionsContainer.widthAnchor constraintEqualToAnchor:_scrollView.widthAnchor constant:-32],

        [_addPollOptionButton.topAnchor constraintEqualToAnchor:_pollOptionsContainer.bottomAnchor constant:10],
        [_addPollOptionButton.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor constant:16],

        [_removePollOptionButton.topAnchor constraintEqualToAnchor:_pollOptionsContainer.bottomAnchor constant:10],
        [_removePollOptionButton.leadingAnchor constraintEqualToAnchor:_addPollOptionButton.trailingAnchor constant:16],

        [_pollDurationControl.topAnchor constraintEqualToAnchor:_addPollOptionButton.bottomAnchor constant:12],
        [_pollDurationControl.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor constant:16],
        [_pollDurationControl.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor constant:-16],

        [_spinner.centerXAnchor constraintEqualToAnchor:_scrollView.centerXAnchor],
        [_spinner.topAnchor constraintEqualToAnchor:_pollDurationControl.bottomAnchor constant:20],
        [_spinner.bottomAnchor constraintEqualToAnchor:_scrollView.bottomAnchor constant:-20],
    ]];

    if (_replyToUsername.length > 0) {
        _textView.text = [NSString stringWithFormat:@"@%@ ", _replyToUsername];
    }

    if (_draftText.length > 0) {
        _textView.text = _draftText;
    }

    if (_editInitialText.length > 0) {
        _textView.text = _editInitialText;
    }

    if (_visibility.length > 0) {
        _currentVisibility = _visibility;
    }

    [self addPollOptionField];
    [self addPollOptionField];

    [_textView becomeFirstResponder];
    [self updateCharacterCount];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_textView becomeFirstResponder];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

#pragma mark - Actions

- (void)cancelTapped {
    if (_draftID.length > 0 && _textView.text.length == 0) {
        [[MADraftManager sharedManager] deleteDraftWithID:_draftID];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveDraftTapped {
    NSString *content = [_textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (content.length == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    [[MADraftManager sharedManager] saveDraftWithText:content
                                   inReplyToStatusID:_replyToStatusID
                                     replyToUsername:_replyToUsername
                                        visibility:_currentVisibility];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveEditTapped {
    NSString *content = [_textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (content.length == 0 || _editStatusID.length == 0) return;

    _spinner.hidden = NO;
    [_spinner startAnimating];
    self.navigationItem.rightBarButtonItem.enabled = NO;

    [[MAAPIClient sharedClient] editStatus:_editStatusID content:content spoilerText:nil completion:^(MAStatus *status, NSError *error) {
        [self->_spinner stopAnimating];
        self->_spinner.hidden = YES;
        self.navigationItem.rightBarButtonItem.enabled = YES;

        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed"
                                                                          message:error.localizedDescription
                                                                   preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:@"MAStatusUpdated" object:nil userInfo:@{@"status": status}];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)postTapped {
    NSString *content = [_textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (content.length == 0 && _mediaAttachments.count == 0) return;
    if (_isPosting) return;

    if (_mediaAttachments.count > 0) {
        [self uploadAndPostWithContent:content];
    } else {
        [self postWithContent:content mediaIDs:nil];
    }
}

- (void)uploadAndPostWithContent:(NSString *)content {
    _isPosting = YES;
    _spinner.hidden = NO;
    [_spinner startAnimating];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;

    NSMutableArray *mediaIDs = [NSMutableArray array];
    __block NSInteger uploadIndex = 0;
    NSInteger totalUploads = _mediaAttachments.count;

    for (NSInteger i = 0; i < totalUploads; i++) {
        NSDictionary *attachment = _mediaAttachments[i];
        UIImage *image = attachment[@"image"];
        NSString *altText = attachment[@"altText"] ?: @"";

        NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
        NSString *filename = [NSString stringWithFormat:@"media_%ld.jpg", (long)i];

        [[MAAPIClient sharedClient] uploadMedia:imageData
                                       filename:filename
                                      mimeType:@"image/jpeg"
                                   description:altText
                                    completion:^(NSDictionary *mediaDict, NSError *error) {
            if (error) {
                [self->_spinner stopAnimating];
                self->_spinner.hidden = YES;
                self->_isPosting = NO;
                self.navigationItem.rightBarButtonItem.enabled = YES;
                self.navigationItem.leftBarButtonItem.enabled = YES;

                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Upload Failed"
                                                                              message:error.localizedDescription
                                                                       preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }

            NSString *mediaID = [mediaDict[@"id"] description];
            if (mediaID) {
                @synchronized(mediaIDs) {
                    [mediaIDs addObject:mediaID];
                }
            }

            uploadIndex++;
            if (uploadIndex == totalUploads) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self postWithContent:content mediaIDs:mediaIDs];
                });
            }
        }];
    }
}

- (void)postWithContent:(NSString *)content mediaIDs:(NSArray *)mediaIDs {
    _spinner.hidden = NO;
    [_spinner startAnimating];
    self.navigationItem.rightBarButtonItem.enabled = NO;

    if (_pollEnabled) {
        NSMutableArray *options = [NSMutableArray array];
        for (UITextField *tf in _pollOptionTextFields) {
            NSString *text = [tf.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (text.length > 0) {
                [options addObject:text];
            }
        }

        if (options.count < 2) {
            [_spinner stopAnimating];
            _spinner.hidden = YES;
            self.navigationItem.rightBarButtonItem.enabled = YES;
            _isPosting = NO;

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Poll"
                                                                          message:@"A poll needs at least 2 options."
                                                                   preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }

        NSInteger durations[] = {3600, 21600, 43200, 86400, 259200, 604800};
        NSInteger expiresIn = durations[_pollDurationControl.selectedSegmentIndex];

        [[MAAPIClient sharedClient] postStatus:content
                                   inReplyToID:_replyToStatusID
                                   visibility:_currentVisibility
                                   spoilerText:nil
                                      sensitive:NO
                                       mediaIDs:mediaIDs
                                    pollOptions:options
                                   pollExpiresIn:expiresIn
                                       language:_currentLanguage.length > 0 ? _currentLanguage : nil
                                     completion:^(MAStatus *status, NSError *error) {
            [self->_spinner stopAnimating];
            self->_spinner.hidden = YES;
            self->_isPosting = NO;
            self.navigationItem.rightBarButtonItem.enabled = YES;

            if (error) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed"
                                                                              message:error.localizedDescription
                                                                       preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }

            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    } else {
        [[MAAPIClient sharedClient] postStatus:content
                                   inReplyToID:_replyToStatusID
                                   visibility:_currentVisibility
                                   spoilerText:nil
                                      sensitive:NO
                                       mediaIDs:mediaIDs
                                    pollOptions:nil
                                   pollExpiresIn:0
                                       language:_currentLanguage.length > 0 ? _currentLanguage : nil
                                     completion:^(MAStatus *status, NSError *error) {
            [self->_spinner stopAnimating];
            self->_spinner.hidden = YES;
            self->_isPosting = NO;
            self.navigationItem.rightBarButtonItem.enabled = YES;

            if (error) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed"
                                                                              message:error.localizedDescription
                                                                       preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }

            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    }
}

#pragma mark - Visibility

- (void)visibilityTapped {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Visibility"
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *options = @[
        @[@"Public", @"public", @"Visible to everyone"],
        @[@"Unlisted", @"unlisted", @"Visible to followers"],
        @[@"Private", @"private", @"Followers only"],
        @[@"Direct", @"direct", @"Mentioned users only"],
    ];

    for (NSArray *option in options) {
        NSString *title = option[0];
        if ([option[1] isEqualToString:_currentVisibility]) {
            title = [title stringByAppendingString:@" ✓"];
        }
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            self->_currentVisibility = option[1];
            [self->_visibilityButton setTitle:[NSString stringWithFormat:@"%@ \u25BC", option[0]] forState:UIControlStateNormal];
        }];
        [sheet addAction:action];
    }

    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        sheet.modalPresentationStyle = UIModalPresentationPopover;
        sheet.popoverPresentationController.sourceView = _visibilityButton;
        sheet.popoverPresentationController.sourceRect = _visibilityButton.bounds;
    }

    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - Language

- (void)languageTapped {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Post Language"
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *languages = @[
        @[@"English", @"en"],
        @[@"Spanish", @"es"],
        @[@"French", @"fr"],
        @[@"German", @"de"],
        @[@"Portuguese", @"pt"],
        @[@"Italian", @"it"],
        @[@"Dutch", @"nl"],
        @[@"Japanese", @"ja"],
        @[@"Chinese", @"zh"],
        @[@"Korean", @"ko"],
        @[@"Russian", @"ru"],
        @[@"Arabic", @"ar"],
        @[@"Hindi", @"hi"],
        @[@"Turkish", @"tr"],
        @[@"Polish", @"pl"],
        @[@"Swedish", @"sv"],
        @[@"Danish", @"da"],
        @[@"Finnish", @"fi"],
        @[@"Norwegian", @"nb"],
        @[@"Czech", @"cs"],
        @[@"Greek", @"el"],
        @[@"Hebrew", @"he"],
        @[@"Thai", @"th"],
        @[@"Indonesian", @"id"],
        @[@"Catalan", @"ca"],
        @[@"Auto-detect", @""],
    ];

    for (NSArray *lang in languages) {
        NSString *title = lang[0];
        if ([lang[1] isEqualToString:_currentLanguage]) {
            title = [title stringByAppendingString:@" ✓"];
        }
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            self->_currentLanguage = lang[1];
            if ([lang[1] length] > 0) {
                [self->_languageButton setTitle:[NSString stringWithFormat:@"%@ \u2713", lang[0]] forState:UIControlStateNormal];
            } else {
                [self->_languageButton setTitle:@"Language" forState:UIControlStateNormal];
            }
        }];
        [sheet addAction:action];
    }

    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        sheet.modalPresentationStyle = UIModalPresentationPopover;
        sheet.popoverPresentationController.sourceView = _languageButton;
        sheet.popoverPresentationController.sourceRect = _languageButton.bounds;
    }

    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - Media

- (void)addMediaTapped {
    if (_mediaAttachments.count >= 4) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Maximum Media"
                                                                      message:@"You can attach up to 4 images."
                                                               preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Add Media"
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Photo Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self showImagePickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
        }]];
    }

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self showImagePickerWithSource:UIImagePickerControllerSourceTypeCamera];
        }]];
    }

    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        sheet.modalPresentationStyle = UIModalPresentationPopover;
        sheet.popoverPresentationController.sourceView = _addMediaButton;
        sheet.popoverPresentationController.sourceRect = _addMediaButton.bounds;
    }

    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showImagePickerWithSource:(UIImagePickerControllerSourceType)source {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = source;
    picker.delegate = (id)self;
    picker.allowsEditing = NO;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && source == UIImagePickerControllerSourceTypePhotoLibrary) {
        picker.modalPresentationStyle = UIModalPresentationPopover;
        picker.popoverPresentationController.sourceView = _addMediaButton;
        picker.popoverPresentationController.sourceRect = _addMediaButton.bounds;
    }

    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (!image) {
        [picker dismissViewControllerAnimated:YES completion:nil];
        return;
    }

    [picker dismissViewControllerAnimated:YES completion:nil];

    NSMutableDictionary *attachment = [NSMutableDictionary dictionary];
    attachment[@"image"] = image;
    attachment[@"altText"] = @"";
    [_mediaAttachments addObject:attachment];

    [self rebuildMediaPreviews];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)rebuildMediaPreviews {
    for (UIView *v in _mediaPreviewViews) {
        [v removeFromSuperview];
    }
    [_mediaPreviewViews removeAllObjects];

    _mediaPreviewScrollView.hidden = (_mediaAttachments.count == 0);

    for (NSInteger i = 0; i < (NSInteger)_mediaAttachments.count; i++) {
        NSDictionary *attachment = _mediaAttachments[i];
        UIImage *image = attachment[@"image"];

        UIView *container = [[UIView alloc] initWithFrame:CGRectMake(i * 90, 0, 80, 80)];
        container.clipsToBounds = YES;
        container.layer.cornerRadius = 6;
        container.layer.borderWidth = 1;
        container.layer.borderColor = [MATheme secondaryTextColor].CGColor;

        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 80, 60)];
        imageView.image = image;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [container addSubview:imageView];

        UIButton *removeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        removeBtn.frame = CGRectMake(62, 0, 18, 18);
        removeBtn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        [removeBtn setTitle:@"x" forState:UIControlStateNormal];
        [removeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        removeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:10];
        removeBtn.layer.cornerRadius = 9;
        removeBtn.tag = i;
        [removeBtn addTarget:self action:@selector(removeMediaTapped:) forControlEvents:UIControlEventTouchUpInside];
        [container addSubview:removeBtn];

        UIButton *altBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        altBtn.frame = CGRectMake(0, 61, 80, 18);
        altBtn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        [altBtn setTitle:@"Alt" forState:UIControlStateNormal];
        [altBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        altBtn.titleLabel.font = [UIFont systemFontOfSize:10];
        altBtn.tag = i;
        [altBtn addTarget:self action:@selector(editAltTextTapped:) forControlEvents:UIControlEventTouchUpInside];
        [container addSubview:altBtn];

        NSString *altText = attachment[@"altText"];
        if (altText.length > 0) {
            altBtn.backgroundColor = [MATheme primaryColor];
        }

        [_mediaPreviewScrollView addSubview:container];
        [_mediaPreviewViews addObject:container];
    }

    _mediaPreviewScrollView.contentSize = CGSizeMake(_mediaAttachments.count * 90, 80);
}

- (void)removeMediaTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index >= 0 && index < (NSInteger)_mediaAttachments.count) {
        [_mediaAttachments removeObjectAtIndex:index];
        [self rebuildMediaPreviews];
    }
}

- (void)editAltTextTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < 0 || index >= (NSInteger)_mediaAttachments.count) return;

    NSMutableDictionary *attachment = _mediaAttachments[index];
    NSString *current = attachment[@"altText"] ?: @"";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alt Text"
                                                                  message:@"Describe this image for people who can't see it"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = current;
        textField.placeholder = @"Image description";
        textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *text = alert.textFields.firstObject.text ?: @"";
        attachment[@"altText"] = text;
        [self rebuildMediaPreviews];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Character Count

- (void)updateCharacterCount {
    NSInteger remaining = _maxCharacters - _textView.text.length;
    _characterCountLabel.text = [NSString stringWithFormat:@"%ld", (long)remaining];
    if (remaining < 0) {
        _characterCountLabel.textColor = [MATheme dangerColor];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else if (remaining < 50) {
        _characterCountLabel.textColor = [MATheme favoriteColor];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        _characterCountLabel.textColor = [MATheme secondaryTextColor];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

#pragma mark - Poll

- (void)pollToggleTapped {
    _pollEnabled = !_pollEnabled;
    [_pollToggleButton setTitle:_pollEnabled ? @"Poll: On" : @"Poll: Off" forState:UIControlStateNormal];

    _pollOptionsContainer.hidden = !_pollEnabled;
    _addPollOptionButton.hidden = !_pollEnabled;
    _removePollOptionButton.hidden = !_pollEnabled;
    _pollDurationControl.hidden = !_pollEnabled;
}

- (void)addPollOptionField {
    if (_pollOptionTextFields.count >= 4) return;

    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.backgroundColor = [MATheme isDarkMode] ? [MATheme primaryDarkColor] : [MATheme cardColor];
    container.layer.cornerRadius = 6;
    container.clipsToBounds = YES;
    [_pollOptionsContainer addSubview:container];

    UITextField *field = [[UITextField alloc] init];
    field.translatesAutoresizingMaskIntoConstraints = NO;
    field.borderStyle = UITextBorderStyleNone;
    field.font = [MATheme fontWithSize:14];
    field.textColor = [MATheme textColor];
    field.placeholder = [NSString stringWithFormat:@"Option %lu", (unsigned long)_pollOptionTextFields.count + 1];
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:field.placeholder attributes:@{
        NSForegroundColorAttributeName: [MATheme secondaryTextColor]
    }];
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.returnKeyType = UIReturnKeyDone;
    [container addSubview:field];
    [_pollOptionTextFields addObject:field];

    [NSLayoutConstraint activateConstraints:@[
        [container.leadingAnchor constraintEqualToAnchor:_pollOptionsContainer.leadingAnchor],
        [container.trailingAnchor constraintEqualToAnchor:_pollOptionsContainer.trailingAnchor],
        [container.heightAnchor constraintEqualToConstant:40],
    ]];

    if (_pollOptionTextFields.count == 1) {
        [container.topAnchor constraintEqualToAnchor:_pollOptionsContainer.topAnchor].active = YES;
    } else {
        NSInteger idx = _pollOptionTextFields.count - 2;
        UITextField *prevField = _pollOptionTextFields[idx];
        UIView *prev = prevField.superview;
        [container.topAnchor constraintEqualToAnchor:prev.bottomAnchor constant:6].active = YES;
    }

    [NSLayoutConstraint activateConstraints:@[
        [field.topAnchor constraintEqualToAnchor:container.topAnchor constant:4],
        [field.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-4],
        [field.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10],
        [field.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10],
    ]];

    [_pollContainerBottom setActive:NO];
    _pollContainerBottom = [_pollOptionsContainer.bottomAnchor constraintEqualToAnchor:container.bottomAnchor];
    _pollContainerBottom.active = YES;
}

- (void)addPollOptionTapped {
    [self addPollOptionField];
}

- (void)removePollOptionTapped {
    if (_pollOptionTextFields.count <= 2) return;

    UITextField *last = _pollOptionTextFields.lastObject;
    UIView *container = last.superview;
    [container removeFromSuperview];
    [_pollOptionTextFields removeLastObject];

    [_pollContainerBottom setActive:NO];
    UITextField *newLast = _pollOptionTextFields.lastObject;
    UIView *newContainer = newLast.superview;
    _pollContainerBottom = [_pollOptionsContainer.bottomAnchor constraintEqualToAnchor:newContainer.bottomAnchor];
    _pollContainerBottom.active = YES;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self updateCharacterCount];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

@end
