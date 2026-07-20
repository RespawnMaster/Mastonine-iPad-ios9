#import "MAProfileEditViewController.h"
#import "MAAPIClient.h"
#import "MAAccount.h"
#import "MATheme.h"
#import "MAImageCache.h"

@interface MAProfileEditViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UITextField *displayNameField;
@property (nonatomic, strong) UITextView *bioTextView;
@property (nonatomic, strong) UIButton *avatarButton;
@property (nonatomic, strong) UIButton *headerButton;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIImageView *headerImageView;
@property (nonatomic, strong) MAAccount *currentAccount;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, assign) BOOL pickingAvatar;

@end

@implementation MAProfileEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [MATheme backgroundColor];
    self.title = @"Edit Profile";

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelTapped)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(saveTapped)];

    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.delegate = (id)self;
    [self.view addSubview:_scrollView];

    _contentView = [[UIView alloc] initWithFrame:CGRectZero];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [_scrollView addSubview:_contentView];

    UILabel *displayNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    displayNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    displayNameLabel.text = @"Display Name";
    displayNameLabel.font = [MATheme boldFontWithSize:14];
    displayNameLabel.textColor = [MATheme secondaryTextColor];
    [_contentView addSubview:displayNameLabel];

    _displayNameField = [[UITextField alloc] initWithFrame:CGRectZero];
    _displayNameField.translatesAutoresizingMaskIntoConstraints = NO;
    _displayNameField.borderStyle = UITextBorderStyleRoundedRect;
    _displayNameField.font = [MATheme fontWithSize:16];
    _displayNameField.textColor = [MATheme textColor];
    _displayNameField.backgroundColor = [MATheme cardColor];
    _displayNameField.placeholder = @"Your display name";
    [_contentView addSubview:_displayNameField];

    UILabel *bioLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    bioLabel.translatesAutoresizingMaskIntoConstraints = NO;
    bioLabel.text = @"Bio";
    bioLabel.font = [MATheme boldFontWithSize:14];
    bioLabel.textColor = [MATheme secondaryTextColor];
    [_contentView addSubview:bioLabel];

    _bioTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    _bioTextView.translatesAutoresizingMaskIntoConstraints = NO;
    _bioTextView.font = [MATheme fontWithSize:16];
    _bioTextView.textColor = [MATheme textColor];
    _bioTextView.backgroundColor = [MATheme cardColor];
    _bioTextView.layer.cornerRadius = 8;
    _bioTextView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    [_contentView addSubview:_bioTextView];

    UILabel *avatarLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    avatarLabel.translatesAutoresizingMaskIntoConstraints = NO;
    avatarLabel.text = @"Avatar";
    avatarLabel.font = [MATheme boldFontWithSize:14];
    avatarLabel.textColor = [MATheme secondaryTextColor];
    [_contentView addSubview:avatarLabel];

    _avatarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _avatarButton.translatesAutoresizingMaskIntoConstraints = NO;
    _avatarButton.layer.cornerRadius = 40;
    _avatarButton.clipsToBounds = YES;
    _avatarButton.backgroundColor = [MATheme cardColor];
    [_avatarButton addTarget:self action:@selector(avatarTapped) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_avatarButton];

    _avatarImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    _avatarImageView.clipsToBounds = YES;
    [_avatarButton addSubview:_avatarImageView];

    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    headerLabel.text = @"Header Image";
    headerLabel.font = [MATheme boldFontWithSize:14];
    headerLabel.textColor = [MATheme secondaryTextColor];
    [_contentView addSubview:headerLabel];

    _headerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _headerButton.translatesAutoresizingMaskIntoConstraints = NO;
    _headerButton.layer.cornerRadius = 8;
    _headerButton.clipsToBounds = YES;
    _headerButton.backgroundColor = [MATheme cardColor];
    [_headerButton addTarget:self action:@selector(headerTapped) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:_headerButton];

    _headerImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _headerImageView.contentMode = UIViewContentModeScaleAspectFill;
    _headerImageView.clipsToBounds = YES;
    [_headerButton addSubview:_headerImageView];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.translatesAutoresizingMaskIntoConstraints = NO;
    _spinner.hidesWhenStopped = YES;
    [_contentView addSubview:_spinner];

    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [_contentView.topAnchor constraintEqualToAnchor:_scrollView.topAnchor],
        [_contentView.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor],
        [_contentView.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor],
        [_contentView.bottomAnchor constraintEqualToAnchor:_scrollView.bottomAnchor],
        [_contentView.widthAnchor constraintEqualToAnchor:_scrollView.widthAnchor],

        [displayNameLabel.topAnchor constraintEqualToAnchor:_contentView.topAnchor constant:16],
        [displayNameLabel.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:16],
        [displayNameLabel.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor constant:-16],

        [_displayNameField.topAnchor constraintEqualToAnchor:displayNameLabel.bottomAnchor constant:6],
        [_displayNameField.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:16],
        [_displayNameField.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor constant:-16],
        [_displayNameField.heightAnchor constraintEqualToConstant:40],

        [bioLabel.topAnchor constraintEqualToAnchor:_displayNameField.bottomAnchor constant:20],
        [bioLabel.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:16],
        [bioLabel.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor constant:-16],

        [_bioTextView.topAnchor constraintEqualToAnchor:bioLabel.bottomAnchor constant:6],
        [_bioTextView.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:16],
        [_bioTextView.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor constant:-16],
        [_bioTextView.heightAnchor constraintEqualToConstant:100],

        [avatarLabel.topAnchor constraintEqualToAnchor:_bioTextView.bottomAnchor constant:20],
        [avatarLabel.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:16],
        [avatarLabel.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor constant:-16],

        [_avatarButton.topAnchor constraintEqualToAnchor:avatarLabel.bottomAnchor constant:6],
        [_avatarButton.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:16],
        [_avatarButton.widthAnchor constraintEqualToConstant:80],
        [_avatarButton.heightAnchor constraintEqualToConstant:80],

        [_avatarImageView.topAnchor constraintEqualToAnchor:_avatarButton.topAnchor],
        [_avatarImageView.leadingAnchor constraintEqualToAnchor:_avatarButton.leadingAnchor],
        [_avatarImageView.trailingAnchor constraintEqualToAnchor:_avatarButton.trailingAnchor],
        [_avatarImageView.bottomAnchor constraintEqualToAnchor:_avatarButton.bottomAnchor],

        [headerLabel.topAnchor constraintEqualToAnchor:_avatarButton.bottomAnchor constant:20],
        [headerLabel.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:16],
        [headerLabel.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor constant:-16],

        [_headerButton.topAnchor constraintEqualToAnchor:headerLabel.bottomAnchor constant:6],
        [_headerButton.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:16],
        [_headerButton.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor constant:-16],
        [_headerButton.heightAnchor constraintEqualToConstant:120],

        [_headerImageView.topAnchor constraintEqualToAnchor:_headerButton.topAnchor],
        [_headerImageView.leadingAnchor constraintEqualToAnchor:_headerButton.leadingAnchor],
        [_headerImageView.trailingAnchor constraintEqualToAnchor:_headerButton.trailingAnchor],
        [_headerImageView.bottomAnchor constraintEqualToAnchor:_headerButton.bottomAnchor],

        [_spinner.topAnchor constraintEqualToAnchor:_headerButton.bottomAnchor constant:20],
        [_spinner.centerXAnchor constraintEqualToAnchor:_contentView.centerXAnchor],
        [_spinner.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor constant:-20],
    ]];

    [self loadProfile];
}

- (void)loadProfile {
    _spinner.hidden = NO;
    [_spinner startAnimating];
    self.navigationItem.rightBarButtonItem.enabled = NO;

    [[MAAPIClient sharedClient] verifyCredentialsWithCompletion:^(MAAccount *account, NSError *error) {
        self->_spinner.hidden = YES;
        [self->_spinner stopAnimating];
        self.navigationItem.rightBarButtonItem.enabled = YES;

        if (account) {
            self->_currentAccount = account;
            [self populateFields];
        }
    }];
}

- (void)populateFields {
    if (!_currentAccount) return;
    _displayNameField.text = _currentAccount.displayName;

    NSString *bio = _currentAccount.note;
    if ([bio hasPrefix:@"<p>"]) {
        NSMutableString *stripped = [bio mutableCopy];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<[^>]+>" options:0 error:nil];
        [regex replaceMatchesInString:stripped options:0 range:NSMakeRange(0, stripped.length) withTemplate:@""];
        bio = stripped;
    }
    _bioTextView.text = bio;

    NSURL *avatarURL = [_currentAccount avatarURL];
    if (avatarURL) {
        [[MAImageCache sharedCache] fetchImageAtURL:avatarURL completion:^(UIImage *image) {
            if (image) {
                self->_avatarImageView.image = image;
            }
        }];
    }

    NSURL *headerURL = [_currentAccount headerURL];
    if (headerURL) {
        [[MAImageCache sharedCache] fetchImageAtURL:headerURL completion:^(UIImage *image) {
            if (image) {
                self->_headerImageView.image = image;
            }
        }];
    }
}

- (void)cancelTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveTapped {
    NSString *displayName = _displayNameField.text ?: @"";
    NSString *bio = _bioTextView.text ?: @"";

    _spinner.hidden = NO;
    [_spinner startAnimating];
    self.navigationItem.rightBarButtonItem.enabled = NO;

    NSString *htmlBio = [NSString stringWithFormat:@"<p>%@</p>", bio];

    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    settings[@"display_name"] = displayName;
    settings[@"note"] = htmlBio;

    [[MAAPIClient sharedClient] updateAccountSettings:settings completion:^(MAAccount *account, NSError *error) {
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

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Saved"
                                                                       message:@"Profile updated."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

#pragma mark - Avatar / Header

- (void)avatarTapped {
    _pickingAvatar = YES;
    [self presentImagePicker];
}

- (void)headerTapped {
    _pickingAvatar = NO;
    [self presentImagePicker];
}

- (void)presentImagePicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = (id)self;
    picker.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *pop = picker.popoverPresentationController;
    pop.sourceView = _pickingAvatar ? _avatarButton : _headerButton;
    pop.sourceRect = _pickingAvatar ? _avatarButton.bounds : _headerButton.bounds;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];

    if (!image) return;

    if (_pickingAvatar) {
        _avatarImageView.image = image;
        [self uploadProfileImage:image asAvatar:YES];
    } else {
        _headerImageView.image = image;
        [self uploadProfileImage:image asAvatar:NO];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)uploadProfileImage:(UIImage *)image asAvatar:(BOOL)isAvatar {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    if (!imageData) return;

    NSString *filename = isAvatar ? @"avatar.jpg" : @"header.jpg";
    _spinner.hidden = NO;
    [_spinner startAnimating];

    [[MAAPIClient sharedClient] uploadMedia:imageData
                                   filename:filename
                                  mimeType:@"image/jpeg"
                               description:nil
                                completion:^(NSDictionary *mediaDict, NSError *error) {
        self->_spinner.hidden = YES;
        [self->_spinner stopAnimating];

        if (error || !mediaDict) return;

        NSString *mediaID = [mediaDict[@"id"] description];
        if (!mediaID) return;

        NSString *key = isAvatar ? @"avatar" : @"header";
        NSDictionary *settings = @{ key: mediaID };

        [[MAAPIClient sharedClient] updateAccountSettings:settings completion:^(MAAccount *account, NSError *error) {
            if (account) {
                self->_currentAccount = account;
            }
        }];
    }];
}

@end
