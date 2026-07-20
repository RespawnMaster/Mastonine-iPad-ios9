#import "MAAppDelegate.h"
#import "MAMainTabBarController.h"
#import "MALoginViewController.h"
#import "MAAPIClient.h"
#import "MAOAuthManager.h"
#import "MATheme.h"

@implementation MAAppDelegate

+ (instancetype)sharedDelegate {
    return (MAAppDelegate *)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];

    [MATheme applyAppearance];

    [self showRootViewControllerAnimated:NO];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)showRootViewControllerAnimated:(BOOL)animated {
    NSString *instanceURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"instance_url"];
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"access_token"];

    if (instanceURL && accessToken) {
        [MAAPIClient sharedClient].baseURL = [NSURL URLWithString:instanceURL];
        [MAAPIClient sharedClient].accessToken = accessToken;
        MAMainTabBarController *tabBar = [[MAMainTabBarController alloc] init];
        self.window.rootViewController = tabBar;
    } else {
        MALoginViewController *login = [[MALoginViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:login];
        self.window.rootViewController = nav;
    }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([url.host isEqualToString:@"share"]) {
        return [self handleShareURL:url];
    }
    return [self handleOAuthURL:url];
}

- (BOOL)handleShareURL:(NSURL *)url {
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSString *shareText = nil;
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"text"]) {
            shareText = item.value;
            break;
        }
    }

    if (shareText.length == 0) {
        return NO;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"MAShareReceived"
                                                        object:nil
                                                      userInfo:@{@"text": shareText}];
    return YES;
}

- (void)checkForPendingShares {
    NSString *sharedDir = @"/var/mobile/Documents/Mastonine";
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm contentsOfDirectoryAtPath:sharedDir error:nil];
    for (NSString *file in files) {
        if (![file hasPrefix:@"share_"]) continue;
        NSString *filepath = [sharedDir stringByAppendingPathComponent:file];
        NSData *data = [NSData dataWithContentsOfFile:filepath];
        if (data) {
            NSDictionary *shareData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (shareData[@"text"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MAShareReceived"
                                                                    object:nil
                                                                  userInfo:shareData];
            }
        }
        [fm removeItemAtPath:filepath error:nil];
    }
}

- (BOOL)handleOAuthURL:(NSURL *)url {
    if (!url) return NO;
    if (![url.scheme isEqualToString:@"mastonine"]) return NO;

    NSString *code = nil;
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"code"]) {
            code = item.value;
            break;
        }
    }

    if (!code) {
        return NO;
    }

    NSString *instanceURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"instance_url"];
    NSString *clientID = [[NSUserDefaults standardUserDefaults] objectForKey:@"client_id"];
    NSString *clientSecret = [[NSUserDefaults standardUserDefaults] objectForKey:@"client_secret"];

    if (!instanceURL || !clientID || !clientSecret) {
        return NO;
    }

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.center = self.window.center;
    spinner.color = [MATheme primaryColor];
    [self.window addSubview:spinner];
    [spinner startAnimating];

    [MAOAuthManager authorizeApplicationWithClientID:clientID
                                        clientSecret:clientSecret
                                            instance:instanceURL
                                                code:code
                                        redirectURI:@"mastonine://oauth/callback"
                                          completion:^(NSString *accessToken, NSError *error) {
        [spinner stopAnimating];
        [spinner removeFromSuperview];

        if (error || !accessToken) {
            NSString *detail = error.localizedDescription ?: @"Unknown error";
            if (error.userInfo[NSLocalizedDescriptionKey]) {
                NSString *responseBody = error.userInfo[@"responseBody"];
                if (responseBody) {
                    detail = [NSString stringWithFormat:@"%@\n\nResponse: %@", detail, responseBody];
                }
            }
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Authorization Failed"
                                                                          message:detail
                                                                   preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
            return;
        }

        [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:@"access_token"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [MAAPIClient sharedClient].baseURL = [NSURL URLWithString:instanceURL];
        [MAAPIClient sharedClient].accessToken = accessToken;

        MAMainTabBarController *tabBar = [[MAMainTabBarController alloc] init];
        self.window.rootViewController = tabBar;
    }];

    return YES;
}

@end
