#import "MALoginViewController.h"
#import "MAOAuthManager.h"
#import "MAAPIClient.h"
#import "MAMainTabBarController.h"
#import "MAInstanceSelectionViewController.h"
#import "MATheme.h"

@interface MALoginViewController ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UITextField *instanceField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *exploreButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, copy) NSString *pendingClientID;
@property (nonatomic, copy) NSString *pendingClientSecret;
@property (nonatomic, strong) UIWebView *oauthWebView;

@end

@implementation MALoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [MATheme backgroundColor];

    if (self.navigationController) {
        self.navigationController.navigationBarHidden = YES;
    }

    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;
    BOOL isLandscape = screenWidth > screenHeight;

    CGFloat centerX = self.view.center.x;
    CGFloat topPadding = isLandscape ? 40 : 80;

    _logoView = [[UIImageView alloc] initWithFrame:CGRectMake(centerX - 40, topPadding, 80, 80)];
    _logoView.image = [UIImage imageNamed:@"mastonine"];
    _logoView.contentMode = UIViewContentModeScaleAspectFill;
    _logoView.layer.cornerRadius = 18;
    _logoView.clipsToBounds = YES;
    [self.view addSubview:_logoView];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, topPadding + 100, screenWidth - 40, 40)];
    _titleLabel.text = @"Mastonine";
    _titleLabel.textColor = [MATheme textColor];
    _titleLabel.font = [UIFont boldSystemFontOfSize:32];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_titleLabel];

    _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, topPadding + 140, screenWidth - 40, 30)];
    _subtitleLabel.text = @"Sign in to your Mastodon Instance";
    _subtitleLabel.textColor = [MATheme secondaryTextColor];
    _subtitleLabel.font = [MATheme fontWithSize:16];
    _subtitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_subtitleLabel];

    CGFloat fieldWidth = MIN(screenWidth - 60, 400);
    CGFloat fieldY = topPadding + 200;

    UIView *fieldContainer = [[UIView alloc] initWithFrame:CGRectMake(centerX - fieldWidth/2, fieldY, fieldWidth, 50)];
    fieldContainer.backgroundColor = [MATheme cardColor];
    fieldContainer.layer.cornerRadius = 10;
    fieldContainer.layer.borderWidth = 1;
    fieldContainer.layer.borderColor = [MATheme separatorColor].CGColor;
    fieldContainer.clipsToBounds = YES;
    [self.view addSubview:fieldContainer];

    _instanceField = [[UITextField alloc] initWithFrame:CGRectMake(16, 0, fieldWidth - 32, 50)];
    _instanceField.placeholder = @"e.g., mastodon.social";
    _instanceField.textColor = [MATheme textColor];
    _instanceField.font = [MATheme fontWithSize:17];
    _instanceField.keyboardType = UIKeyboardTypeURL;
    _instanceField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _instanceField.autocorrectionType = UITextAutocorrectionTypeNo;
    _instanceField.returnKeyType = UIReturnKeyGo;
    _instanceField.delegate = (id)self;
    _instanceField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"e.g., mastodon.social"
                                                                          attributes:@{
        NSForegroundColorAttributeName: [MATheme secondaryTextColor],
        NSFontAttributeName: [MATheme fontWithSize:17]
    }];
    [fieldContainer addSubview:_instanceField];

    _loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _loginButton.frame = CGRectMake(centerX - fieldWidth/2, fieldY + 70, fieldWidth, 50);
    _loginButton.backgroundColor = [MATheme primaryColor];
    [_loginButton setTitle:@"Sign In" forState:UIControlStateNormal];
    [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _loginButton.titleLabel.font = [MATheme boldFontWithSize:18];
    _loginButton.layer.cornerRadius = 10;
    [_loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_loginButton];

    _exploreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _exploreButton.frame = CGRectMake(centerX - fieldWidth/2, fieldY + 130, fieldWidth, 50);
    [_exploreButton setTitle:@"Explore Servers" forState:UIControlStateNormal];
    [_exploreButton setTitleColor:[MATheme primaryColor] forState:UIControlStateNormal];
    _exploreButton.titleLabel.font = [MATheme fontWithSize:16];
    [_exploreButton addTarget:self action:@selector(exploreTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_exploreButton];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _spinner.center = self.view.center;
    _spinner.color = [MATheme primaryColor];
    _spinner.hidesWhenStopped = YES;
    [self.view addSubview:_spinner];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)loginTapped {
    NSString *instance = [_instanceField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (instance.length == 0) {
        [self showError:@"Please enter an instance domain"];
        return;
    }

    if (![instance containsString:@"."]) {
        instance = [instance stringByAppendingString:@".social"];
        _instanceField.text = instance;
    }

    if (![instance hasPrefix:@"http"]) {
        instance = [@"https://" stringByAppendingString:instance];
    }

    [_spinner startAnimating];
    _loginButton.enabled = NO;

    NSString *redirectURI = @"mastonine://oauth/callback";

    [MAOAuthManager registerApplicationWithInstance:instance
                                        clientName:@"Mastonine"
                                       redirectURI:redirectURI
                                             scopes:@"read write follow"
                                        completion:^(NSString *clientID, NSString *clientSecret, NSURL *authURL, NSError *error) {
        [self->_spinner stopAnimating];
        self->_loginButton.enabled = YES;

        if (error) {
            [self showError:error.localizedDescription ?: @"Failed to connect to instance"];
            return;
        }

        self.pendingClientID = clientID;
        self.pendingClientSecret = clientSecret;

        [[NSUserDefaults standardUserDefaults] setObject:instance forKey:@"instance_url"];
        [[NSUserDefaults standardUserDefaults] setObject:clientID forKey:@"client_id"];
        [[NSUserDefaults standardUserDefaults] setObject:clientSecret forKey:@"client_secret"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        if (authURL) {
            [self presentOAuthWebViewWithURL:authURL];
        }
    }];
}

- (void)presentOAuthWebViewWithURL:(NSURL *)authURL {
    _oauthWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    _oauthWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _oauthWebView.delegate = (id)self;
    [_oauthWebView loadRequest:[NSURLRequest requestWithURL:authURL]];

    UIViewController *webVC = [[UIViewController alloc] init];
    webVC.view = _oauthWebView;
    webVC.title = @"Authorize";
    webVC.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancelOAuth)];

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:webVC];
    nav.navigationBar.barStyle = UIBarStyleDefault;
    nav.navigationBar.translucent = NO;
    nav.navigationBar.barTintColor = [MATheme primaryColor];
    nav.navigationBar.tintColor = [UIColor whiteColor];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)cancelOAuth {
    _oauthWebView = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *urlString = request.URL.absoluteString;
    if ([urlString hasPrefix:@"mastonine://"]) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
        NSString *code = nil;
        for (NSURLQueryItem *item in components.queryItems) {
            if ([item.name isEqualToString:@"code"]) {
                code = item.value;
                break;
            }
        }

        [self dismissViewControllerAnimated:YES completion:^{
            if (code) {
                [self exchangeCode:code];
            } else {
                [self showError:@"Authorization failed: no code received"];
            }
        }];
        return NO;
    }
    return YES;
}

- (void)exchangeCode:(NSString *)code {
    [_spinner startAnimating];
    _loginButton.enabled = NO;

    NSString *instanceURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"instance_url"];
    NSString *clientID = [[NSUserDefaults standardUserDefaults] objectForKey:@"client_id"];
    NSString *clientSecret = [[NSUserDefaults standardUserDefaults] objectForKey:@"client_secret"];

    [MAOAuthManager authorizeApplicationWithClientID:clientID
                                        clientSecret:clientSecret
                                            instance:instanceURL
                                                code:code
                                        redirectURI:@"mastonine://oauth/callback"
                                          completion:^(NSString *accessToken, NSError *error) {
        [self->_spinner stopAnimating];
        self->_loginButton.enabled = YES;

        if (error || !accessToken) {
            NSString *detail = error.localizedDescription ?: @"Unknown error";
            [self showError:detail];
            return;
        }

        [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:@"access_token"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [MAAPIClient sharedClient].baseURL = [NSURL URLWithString:instanceURL];
        [MAAPIClient sharedClient].accessToken = accessToken;

        MAMainTabBarController *tabBar = [[MAMainTabBarController alloc] init];
        [UIApplication sharedApplication].delegate.window.rootViewController = tabBar;
    }];
}

- (void)exploreTapped {
    MAInstanceSelectionViewController *explore = [[MAInstanceSelectionViewController alloc] init];
    explore.delegate = (id)self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:explore];
    nav.navigationBar.barStyle = UIBarStyleDefault;
    nav.navigationBar.translucent = NO;
    nav.navigationBar.barTintColor = [MATheme primaryColor];
    nav.navigationBar.tintColor = [UIColor whiteColor];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)instanceSelectionDidSelectInstance:(NSString *)instance {
    _instanceField.text = instance;
    [self dismissViewControllerAnimated:YES completion:^{
        [self loginTapped];
    }];
}

- (void)showError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self loginTapped];
    return YES;
}

@end
