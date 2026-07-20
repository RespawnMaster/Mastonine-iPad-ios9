#import <Foundation/Foundation.h>

@interface MAMultipleAccountsManager : NSObject

+ (instancetype)sharedManager;
- (void)saveAccountWithInstanceURL:(NSString *)instanceURL accessToken:(NSString *)accessToken username:(NSString *)username displayName:(NSString *)displayName accountID:(NSString *)accountID avatarURL:(NSString *)avatarURL;
- (NSArray *)loadAllAccounts;
- (void)removeAccountAtIndex:(NSInteger)index;
- (void)switchToAccountAtIndex:(NSInteger)index;
- (NSInteger)currentAccountIndex;
- (NSDictionary *)currentAccount;
- (void)signOutCurrentAccount;

@end
