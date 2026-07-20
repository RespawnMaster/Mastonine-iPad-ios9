#import <Foundation/Foundation.h>

@class MAAccount;
@class MAStatus;
@class MANotification;
@class MAList;
@class MAPoll;

@interface MAAPIClient : NSObject

@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *clientID;
@property (nonatomic, copy) NSString *clientSecret;
@property (nonatomic, copy) NSString *currentAccountID;

+ (instancetype)sharedClient;

- (void)verifyCredentialsWithCompletion:(void (^)(MAAccount *account, NSError *error))completion;

- (void)fetchTimeline:(NSString *)timeline
                  maxID:(NSString *)maxID
               sinceID:(NSString *)sinceID
                 limit:(NSInteger)limit
            completion:(void (^)(NSArray *statuses, NSError *error))completion;

- (void)fetchNotificationsSince:(NSString *)sinceID
                         types:(NSArray *)types
                     completion:(void (^)(NSArray *notifications, NSError *error))completion;

- (void)clearNotificationsWithCompletion:(void (^)(NSError *error))completion;

- (void)fetchAccount:(NSString *)accountID
      statusesMaxID:(NSString *)maxID
          completion:(void (^)(NSArray *statuses, NSError *error))completion;

- (void)fetchAccountByID:(NSString *)accountID
              completion:(void (^)(MAAccount *account, NSError *error))completion;

- (void)lookupAccountWithAcct:(NSString *)acct
                   completion:(void (^)(MAAccount *account, NSError *error))completion;

- (void)postStatus:(NSString *)content
       inReplyToID:(NSString *)inReplyToID
       visibility:(NSString *)visibility
       spoilerText:(NSString *)spoilerText
          sensitive:(BOOL)sensitive
           mediaIDs:(NSArray *)mediaIDs
        pollOptions:(NSArray *)pollOptions
       pollExpiresIn:(NSInteger)pollExpiresIn
           language:(NSString *)language
         completion:(void (^)(MAStatus *status, NSError *error))completion;

- (void)postStatus:(NSString *)content
       inReplyToID:(NSString *)inReplyToID
       visibility:(NSString *)visibility
       spoilerText:(NSString *)spoilerText
          sensitive:(BOOL)sensitive
           mediaIDs:(NSArray *)mediaIDs
        completion:(void (^)(MAStatus *status, NSError *error))completion;

- (void)postStatus:(NSString *)content
       inReplyToID:(NSString *)inReplyToID
       visibility:(NSString *)visibility
       spoilerText:(NSString *)spoilerText
          sensitive:(BOOL)sensitive
        completion:(void (^)(MAStatus *status, NSError *error))completion;

- (void)uploadMedia:(NSData *)imageData
           filename:(NSString *)filename
          mimeType:(NSString *)mimeType
       description:(NSString *)description
        completion:(void (^)(NSDictionary *mediaDict, NSError *error))completion;

- (void)boostStatus:(NSString *)statusID
         completion:(void (^)(MAStatus *status, NSError *error))completion;

- (void)unboostStatus:(NSString *)statusID
           completion:(void (^)(MAStatus *status, NSError *error))completion;

- (void)favouriteStatus:(NSString *)statusID
             completion:(void (^)(MAStatus *status, NSError *error))completion;

- (void)unfavouriteStatus:(NSString *)statusID
               completion:(void (^)(MAStatus *status, NSError *error))completion;

- (void)fetchStatus:(NSString *)statusID
         completion:(void (^)(MAStatus *status, NSError *error))completion;

- (void)fetchContextForStatus:(NSString *)statusID
                   completion:(void (^)(NSArray *ancestors, NSArray *descendants, NSError *error))completion;

- (void)searchQuery:(NSString *)query
         completion:(void (^)(NSDictionary *results, NSError *error))completion;

- (void)fetchInstanceInfoWithCompletion:(void (^)(NSDictionary *info, NSError *error))completion;

- (void)updateAccountSettings:(NSDictionary *)settings
                   completion:(void (^)(MAAccount *account, NSError *error))completion;

- (void)followAccount:(NSString *)accountID
           completion:(void (^)(MAAccount *account, NSError *error))completion;

- (void)unfollowAccount:(NSString *)accountID
             completion:(void (^)(MAAccount *account, NSError *error))completion;

- (void)blockAccount:(NSString *)accountID
          completion:(void (^)(MAAccount *account, NSError *error))completion;

- (void)unblockAccount:(NSString *)accountID
            completion:(void (^)(MAAccount *account, NSError *error))completion;

- (void)muteAccount:(NSString *)accountID
         completion:(void (^)(MAAccount *account, NSError *error))completion;

- (void)unmuteAccount:(NSString *)accountID
           completion:(void (^)(MAAccount *account, NSError *error))completion;

- (void)reportAccount:(NSString *)accountID
             statusIDs:(NSArray *)statusIDs
                reason:(NSString *)reason
            completion:(void (^)(NSError *error))completion;

- (void)deleteStatus:(NSString *)statusID
          completion:(void (^)(NSError *error))completion;

- (void)bookmarkStatus:(NSString *)statusID
            completion:(void (^)(MAStatus *status, NSError *error))completion;

- (void)unbookmarkStatus:(NSString *)statusID
              completion:(void (^)(MAStatus *status, NSError *error))completion;

- (void)pinStatus:(NSString *)statusID
       completion:(void (^)(MAStatus *status, NSError *error))completion;

- (void)unpinStatus:(NSString *)statusID
         completion:(void (^)(MAStatus *status, NSError *error))completion;

- (void)acceptFollowRequest:(NSString *)requestID
                 completion:(void (^)(NSError *error))completion;

- (void)rejectFollowRequest:(NSString *)requestID
                 completion:(void (^)(NSError *error))completion;

- (void)fetchRelationshipForAccount:(NSString *)accountID
                         completion:(void (^)(NSDictionary *relationship, NSError *error))completion;

- (void)fetchFollowers:(NSString *)accountID
                 maxID:(NSString *)maxID
            completion:(void (^)(NSArray *accounts, NSError *error))completion;

- (void)fetchFollowing:(NSString *)accountID
                  maxID:(NSString *)maxID
             completion:(void (^)(NSArray *accounts, NSError *error))completion;

- (void)fetchBookmarksWithMaxID:(NSString *)maxID
                     completion:(void (^)(NSArray *statuses, NSError *error))completion;

#pragma mark - Lists

- (void)fetchListsWithCompletion:(void (^)(NSArray *lists, NSError *error))completion;
- (void)createListWithTitle:(NSString *)title completion:(void (^)(MAList *list, NSError *error))completion;
- (void)deleteList:(NSString *)listID completion:(void (^)(NSError *error))completion;
- (void)fetchListTimeline:(NSString *)listID maxID:(NSString *)maxID completion:(void (^)(NSArray *statuses, NSError *error))completion;
- (void)fetchListAccounts:(NSString *)listID maxID:(NSString *)maxID completion:(void (^)(NSArray *accounts, NSError *error))completion;
- (void)addAccountsToList:(NSString *)listID accountIDs:(NSArray *)accountIDs completion:(void (^)(NSError *error))completion;
- (void)removeAccountsFromList:(NSString *)listID accountIDs:(NSArray *)accountIDs completion:(void (^)(NSError *error))completion;

#pragma mark - Explore / Trending

- (void)fetchTrendingTagsWithCompletion:(void (^)(NSArray *tags, NSError *error))completion;
- (void)fetchSuggestedAccountsWithCompletion:(void (^)(NSArray *accounts, NSError *error))completion;
- (void)fetchTrendingStatusesWithCompletion:(void (^)(NSArray *statuses, NSError *error))completion;

#pragma mark - Polls

- (void)voteOnPoll:(NSString *)pollID choices:(NSArray *)choices completion:(void (^)(MAPoll *poll, NSError *error))completion;

#pragma mark - Favourites

- (void)fetchFavouritesWithMaxID:(NSString *)maxID
                      completion:(void (^)(NSArray *statuses, NSError *error))completion;

#pragma mark - Reblogged/Favourited By

- (void)fetchRebloggedByStatusID:(NSString *)statusID
                           maxID:(NSString *)maxID
                      completion:(void (^)(NSArray *accounts, NSError *error))completion;

- (void)fetchFavouritedByStatusID:(NSString *)statusID
                            maxID:(NSString *)maxID
                       completion:(void (^)(NSArray *accounts, NSError *error))completion;

#pragma mark - Edit Status

- (void)editStatus:(NSString *)statusID
           content:(NSString *)content
       spoilerText:(NSString *)spoilerText
        completion:(void (^)(MAStatus *status, NSError *error))completion;

#pragma mark - Edit History

- (void)fetchEditHistoryForStatus:(NSString *)statusID
                       completion:(void (^)(NSArray *edits, NSError *error))completion;

#pragma mark - Followed Hashtags

- (void)fetchFollowedHashtagsWithCompletion:(void (^)(NSArray *tags, NSError *error))completion;
- (void)unfollowHashtag:(NSString *)name completion:(void (^)(NSError *error))completion;
- (void)followHashtag:(NSString *)name completion:(void (^)(NSError *error))completion;

#pragma mark - Blocked / Muted Users

- (void)fetchBlockedAccountsWithMaxID:(NSString *)maxID
                           completion:(void (^)(NSArray *accounts, NSError *error))completion;

- (void)fetchMutedAccountsWithMaxID:(NSString *)maxID
                         completion:(void (^)(NSArray *accounts, NSError *error))completion;

#pragma mark - Lists (Paginated)

- (void)fetchListsMaxID:(NSString *)maxID
             completion:(void (^)(NSArray *lists, NSError *error))completion;

#pragma mark - Push Subscription

- (void)fetchPushSubscriptionWithCompletion:(void (^)(NSDictionary *subscription, NSError *error))completion;

- (void)updatePushSubscriptionAlerts:(NSDictionary *)alerts
                          completion:(void (^)(NSDictionary *subscription, NSError *error))completion;

- (void)deletePushSubscriptionWithCompletion:(void (^)(NSError *error))completion;

@end
