#import "MAMultipleAccountsManager.h"
#import "MAAPIClient.h"

static NSString *const kMultipleAccountsKey = @"multiple_accounts";
static NSString *const kCurrentAccountIndexKey = @"current_account_index";

@implementation MAMultipleAccountsManager

+ (instancetype)sharedManager {
    static MAMultipleAccountsManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MAMultipleAccountsManager alloc] init];
    });
    return manager;
}

- (void)saveAccountWithInstanceURL:(NSString *)instanceURL accessToken:(NSString *)accessToken username:(NSString *)username displayName:(NSString *)displayName accountID:(NSString *)accountID avatarURL:(NSString *)avatarURL {
    NSMutableArray *accounts = [[[NSUserDefaults standardUserDefaults] arrayForKey:kMultipleAccountsKey] mutableCopy] ?: [NSMutableArray array];

    NSDictionary *newAccount = @{
        @"instanceURL": instanceURL ?: @"",
        @"accessToken": accessToken ?: @"",
        @"username": username ?: @"",
        @"displayName": displayName ?: @"",
        @"accountID": accountID ?: @"",
        @"avatarURL": avatarURL ?: @""
    };

    // Replace if same instanceURL + username already exists
    NSInteger existingIndex = NSNotFound;
    for (NSInteger i = 0; i < (NSInteger)accounts.count; i++) {
        NSDictionary *existing = accounts[i];
        if ([existing[@"instanceURL"] isEqualToString:instanceURL] && [existing[@"username"] isEqualToString:username]) {
            existingIndex = i;
            break;
        }
    }

    if (existingIndex != NSNotFound) {
        accounts[existingIndex] = newAccount;
        [[NSUserDefaults standardUserDefaults] setInteger:existingIndex forKey:kCurrentAccountIndexKey];
    } else {
        [accounts addObject:newAccount];
        [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)(accounts.count - 1) forKey:kCurrentAccountIndexKey];
    }

    [[NSUserDefaults standardUserDefaults] setObject:accounts forKey:kMultipleAccountsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)loadAllAccounts {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kMultipleAccountsKey] ?: @[];
}

- (void)removeAccountAtIndex:(NSInteger)index {
    NSMutableArray *accounts = [[[NSUserDefaults standardUserDefaults] arrayForKey:kMultipleAccountsKey] mutableCopy];
    if (!accounts || index < 0 || index >= (NSInteger)accounts.count) {
        return;
    }

    [accounts removeObjectAtIndex:index];
    [[NSUserDefaults standardUserDefaults] setObject:accounts forKey:kMultipleAccountsKey];

    NSInteger currentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kCurrentAccountIndexKey];
    if (currentIndex >= (NSInteger)accounts.count) {
        currentIndex = MAX(0, (NSInteger)accounts.count - 1);
    }
    [[NSUserDefaults standardUserDefaults] setInteger:currentIndex forKey:kCurrentAccountIndexKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)switchToAccountAtIndex:(NSInteger)index {
    NSArray *accounts = [self loadAllAccounts];
    if (index < 0 || index >= (NSInteger)accounts.count) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:kCurrentAccountIndexKey];

    NSDictionary *account = accounts[index];
    [MAAPIClient sharedClient].baseURL = [NSURL URLWithString:account[@"instanceURL"]];
    [MAAPIClient sharedClient].accessToken = account[@"accessToken"];

    [[NSUserDefaults standardUserDefaults] setObject:account[@"instanceURL"] forKey:@"instance_url"];
    [[NSUserDefaults standardUserDefaults] setObject:account[@"accessToken"] forKey:@"access_token"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)currentAccountIndex {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kCurrentAccountIndexKey];
}

- (NSDictionary *)currentAccount {
    NSArray *accounts = [self loadAllAccounts];
    NSInteger index = [self currentAccountIndex];
    if (index >= 0 && index < (NSInteger)accounts.count) {
        return accounts[index];
    }
    return nil;
}

- (void)signOutCurrentAccount {
    NSInteger index = [self currentAccountIndex];
    [self removeAccountAtIndex:index];

    NSArray *remaining = [self loadAllAccounts];
    if (remaining.count > 0) {
        [self switchToAccountAtIndex:0];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"instance_url"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"access_token"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentAccountIndexKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
