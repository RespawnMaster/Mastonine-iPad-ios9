#import <Foundation/Foundation.h>

@class MAStatus;
@class MAAccount;

@interface MASpotlightIndexer : NSObject

+ (void)indexStatus:(MAStatus *)status;
+ (void)indexAccount:(MAAccount *)account;
+ (void)removeStatusWithID:(NSString *)statusID;
+ (void)removeAccountWithID:(NSString *)accountID;
+ (void)removeAll;

@end
