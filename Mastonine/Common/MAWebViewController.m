#import "MAWebViewController.h"
#import "MATheme.h"

@interface MAWebViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) UIBarButtonItem *forwardButton;
@property (nonatomic, strong) UIBarButtonItem *shareButton;
@property (nonatomic, strong) UIBarButtonItem *closeButton;
@property (nonatomic, strong) UIBarButtonItem *flexSpace;
@property (nonatomic, strong) UIBarButtonItem *fixedSpace;

@end

@implementation MAWebViewController

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    _webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    _webView.delegate = self;
    _webView.scalesPageToFit = YES;
    [self.view addSubview:_webView];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.translatesAutoresizingMaskIntoConstraints = NO;
    _spinner.hidesWhenStopped = YES;
    [self.view addSubview:_spinner];

    _toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
    _toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    _toolbar.barTintColor = [MATheme cardColor];
    _toolbar.translucent = NO;
    [self.view addSubview:_toolbar];

    _closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                    style:UIBarButtonItemStylePlain
                                                   target:self
                                                   action:@selector(closeTapped)];
    _closeButton.tintColor = [MATheme primaryColor];

    _backButton = [[UIBarButtonItem alloc] initWithTitle:@"<"
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(backTapped)];
    _backButton.tintColor = [MATheme primaryColor];
    _backButton.enabled = NO;

    _forwardButton = [[UIBarButtonItem alloc] initWithTitle:@">"
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(forwardTapped)];
    _forwardButton.tintColor = [MATheme primaryColor];
    _forwardButton.enabled = NO;

    _shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                target:self
                                                                action:@selector(shareTapped)];
    _shareButton.tintColor = [MATheme primaryColor];

    _flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    _fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    _fixedSpace.width = 20;

    _toolbar.items = @[_closeButton, _fixedSpace, _backButton, _flexSpace, _shareButton, _flexSpace, _forwardButton];

    [NSLayoutConstraint activateConstraints:@[
        [_webView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_webView.bottomAnchor constraintEqualToAnchor:_toolbar.topAnchor],

        [_spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_spinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],

        [_toolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_toolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_toolbar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_toolbar.heightAnchor constraintEqualToConstant:44],
    ]];

    self.title = _url.host;
    self.navigationItem.leftBarButtonItem = _closeButton;

    if (_url) {
        NSURLRequest *request = [NSURLRequest requestWithURL:_url];
        [_webView loadRequest:request];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_webView stopLoading];
}

#pragma mark - Actions

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)backTapped {
    if ([_webView canGoBack]) {
        [_webView goBack];
    }
}

- (void)forwardTapped {
    if ([_webView canGoForward]) {
        [_webView goForward];
    }
}

- (void)shareTapped {
    NSArray *items = @[_url];
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:items
                                                                         applicationActivities:nil];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        activity.modalPresentationStyle = UIModalPresentationPopover;
        activity.popoverPresentationController.barButtonItem = _shareButton;
    }

    [self presentViewController:activity animated:YES completion:nil];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [_spinner startAnimating];
    self.title = @"Loading...";
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [_spinner stopAnimating];
    NSString *pageTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (pageTitle.length > 0) {
        self.title = pageTitle;
    } else {
        self.title = _url.host;
    }
    _backButton.enabled = [webView canGoBack];
    _forwardButton.enabled = [webView canGoForward];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [_spinner stopAnimating];
    self.title = _url.host;
    _backButton.enabled = [webView canGoBack];
    _forwardButton.enabled = [webView canGoForward];
}

@end
