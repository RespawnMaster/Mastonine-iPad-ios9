#import "MAMultipleAccountsViewController.h"
#import "MAMultipleAccountsManager.h"
#import "MAAPIClient.h"
#import "MATheme.h"
#import "MASpotlightIndexer.h"
#import "MAImageCache.h"

@interface MAMultipleAccountsViewController ()

@property (nonatomic, strong) NSArray *accounts;

@end

@implementation MAMultipleAccountsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Accounts";
    self.tableView.backgroundColor = [MATheme backgroundColor];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add Account"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(addAccount)];

    [self loadAccounts];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadAccounts];
}

- (void)loadAccounts {
    self.accounts = [[MAMultipleAccountsManager sharedManager] loadAllAccounts];
    [self.tableView reloadData];
}

#pragma mark - Actions

- (void)addAccount {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Account"
                                                                  message:@"This will sign out of the current account. You can then sign in with a different account."
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"instance_url"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"access_token"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"client_id"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"client_secret"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [MASpotlightIndexer removeAll];
        exit(0);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)switchToAccountAtIndex:(NSInteger)index {
    [[MAMultipleAccountsManager sharedManager] switchToAccountAtIndex:index];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Account Switched"
                                                                  message:@"The app needs to restart to switch accounts."
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        exit(0);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.accounts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"AccountCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }

    NSDictionary *account = self.accounts[indexPath.row];

    NSString *display = account[@"displayName"];
    if (display.length == 0) {
        display = account[@"username"];
    }
    cell.textLabel.text = display;
    cell.detailTextLabel.text = account[@"instanceURL"];

    NSString *avatarURL = account[@"avatarURL"];
    if (avatarURL.length > 0) {
        UIImage *cached = [[MAImageCache sharedCache] cachedImageForURL:[NSURL URLWithString:avatarURL]];
        if (cached) {
            cell.imageView.image = cached;
        } else {
            cell.imageView.image = nil;
            [[MAImageCache sharedCache] fetchImageAtURL:[NSURL URLWithString:avatarURL] completion:^(UIImage *image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UITableViewCell *updateCell = [tableView cellForRowAtIndexPath:indexPath];
                    if (updateCell) {
                        updateCell.imageView.image = image;
                        [updateCell setNeedsLayout];
                    }
                });
            }];
        }
        cell.imageView.layer.cornerRadius = 20;
        cell.imageView.clipsToBounds = YES;
    } else {
        cell.imageView.image = nil;
    }

    NSInteger currentIndex = [[MAMultipleAccountsManager sharedManager] currentAccountIndex];
    if (indexPath.row == currentIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    cell.backgroundColor = [MATheme cardColor];
    cell.textLabel.textColor = [MATheme textColor];
    cell.detailTextLabel.textColor = [MATheme secondaryTextColor];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSInteger currentIndex = [[MAMultipleAccountsManager sharedManager] currentAccountIndex];

        [[MAMultipleAccountsManager sharedManager] removeAccountAtIndex:indexPath.row];

        NSArray *remaining = [[MAMultipleAccountsManager sharedManager] loadAllAccounts];

        if (remaining.count == 0) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"instance_url"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"access_token"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [MASpotlightIndexer removeAll];
            exit(0);
            return;
        }

        if (indexPath.row == currentIndex) {
            [[MAMultipleAccountsManager sharedManager] switchToAccountAtIndex:0];
            exit(0);
            return;
        }

        [self loadAccounts];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSInteger currentIndex = [[MAMultipleAccountsManager sharedManager] currentAccountIndex];
    if (indexPath.row == currentIndex) {
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Switch Account"
                                                                  message:@"Switching accounts requires an app restart. Continue?"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Switch" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self switchToAccountAtIndex:indexPath.row];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
