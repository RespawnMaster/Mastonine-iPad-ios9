#import "MAAPIClient.h"
#import "MAAccount.h"
#import "MAStatus.h"
#import "MANotification.h"
#import "MAList.h"
#import "MAPoll.h"

@interface MAAPIClient ()

@property (nonatomic, strong) NSURLSession *urlSession;

@end

@implementation MAAPIClient

+ (instancetype)sharedClient {
    static MAAPIClient *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[MAAPIClient alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 30;
        config.timeoutIntervalForResource = 60;
        _urlSession = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

#pragma mark - Request Building

- (NSMutableURLRequest *)requestForPath:(NSString *)path method:(NSString *)method {
    NSURL *url = [NSURL URLWithString:path relativeToURL:self.baseURL];
    if (!url) url = [NSURL URLWithString:[self.baseURL.absoluteString stringByAppendingString:path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"Mastonine/1.0" forHTTPHeaderField:@"User-Agent"];

    if (self.accessToken) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken]
       forHTTPHeaderField:@"Authorization"];
    }

    return request;
}

- (void)performRequest:(NSMutableURLRequest *)request
            completion:(void (^)(id, NSError *))completion {

    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request
                                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
            NSError *apiError = [NSError errorWithDomain:@"com.mastonine.api"
                                                   code:httpResponse.statusCode
                                               userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP %ld", (long)httpResponse.statusCode],
                @"responseBody": data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"" : @""
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, apiError);
            });
            return;
        }

        if (!data || data.length == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil);
            });
            return;
        }

        NSError *jsonError = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(json, jsonError);
        });
    }];
    [task resume];
}

- (void)performPOSTRequest:(NSMutableURLRequest *)request
               bodyData:(NSData *)bodyData
             completion:(void (^)(id, NSError *))completion {
    if (bodyData) {
        [request setHTTPBody:bodyData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    [self performRequest:request completion:completion];
}

#pragma mark - Account

- (void)verifyCredentialsWithCompletion:(void (^)(MAAccount *, NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/accounts/verify_credentials" method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        MAAccount *account = [MAAccount accountFromDictionary:json];
        if (account) {
            self.currentAccountID = account.accountID;
        }
        completion(account, nil);
    }];
}

- (void)fetchAccountByID:(NSString *)accountID
              completion:(void (^)(MAAccount *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/accounts/%@", accountID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        completion([MAAccount accountFromDictionary:json], nil);
    }];
}

- (void)lookupAccountWithAcct:(NSString *)acct
                   completion:(void (^)(MAAccount *, NSError *))completion {
    NSString *encoded = [acct stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *path = [NSString stringWithFormat:@"/api/v1/accounts/lookup?acct=%@", encoded];
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        completion([MAAccount accountFromDictionary:json], nil);
    }];
}

#pragma mark - Timeline

- (void)fetchTimeline:(NSString *)timeline
                  maxID:(NSString *)maxID
               sinceID:(NSString *)sinceID
                 limit:(NSInteger)limit
            completion:(void (^)(NSArray *, NSError *))completion {

    NSString *path;
    if ([timeline isEqualToString:@"home"]) {
        path = @"/api/v1/timelines/home";
    } else if ([timeline isEqualToString:@"local"]) {
        path = @"/api/v1/timelines/public?local=true";
    } else if ([timeline isEqualToString:@"federated"]) {
        path = @"/api/v1/timelines/public";
    } else if ([timeline hasPrefix:@"tag/"]) {
        NSString *tag = [timeline substringFromIndex:4];
        path = [NSString stringWithFormat:@"/api/v1/timelines/tag/%@", tag];
    } else {
        path = @"/api/v1/timelines/home";
    }

    NSMutableArray *params = [NSMutableArray array];
    if (maxID) [params addObject:[NSString stringWithFormat:@"max_id=%@", maxID]];
    if (sinceID) [params addObject:[NSString stringWithFormat:@"since_id=%@", sinceID]];
    if (limit > 0) [params addObject:[NSString stringWithFormat:@"limit=%ld", (long)limit]];

    if (params.count > 0) {
        NSString *separator = [path containsString:@"?"] ? @"&" : @"?";
        path = [path stringByAppendingString:separator];
        path = [path stringByAppendingString:[params componentsJoinedByString:@"&"]];
    }

    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *statuses = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAStatus *status = [MAStatus statusFromDictionary:dict];
            if (status) [statuses addObject:status];
        }
        completion(statuses, nil);
    }];
}

#pragma mark - Notifications

- (void)fetchNotificationsSince:(NSString *)sinceID
                         types:(NSArray *)types
                     completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = @"/api/v1/notifications";
    NSMutableArray *params = [NSMutableArray array];
    if (sinceID.length > 0) {
        [params addObject:[NSString stringWithFormat:@"max_id=%@", sinceID]];
    }
    for (NSString *type in types) {
        [params addObject:[NSString stringWithFormat:@"types[]=%@", type]];
    }
    if (params.count > 0) {
        path = [path stringByAppendingFormat:@"?%@", [params componentsJoinedByString:@"&"]];
    }
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *notifications = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MANotification *notif = [MANotification notificationFromDictionary:dict];
            if (notif) [notifications addObject:notif];
        }
        completion(notifications, nil);
    }];
}

- (void)fetchNotificationsSince:(NSString *)sinceID
                     completion:(void (^)(NSArray *, NSError *))completion {
    [self fetchNotificationsSince:sinceID types:nil completion:completion];
}

- (void)clearNotificationsWithCompletion:(void (^)(NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/notifications/clear" method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        completion(error);
    }];
}

#pragma mark - Account Timeline

- (void)fetchAccount:(NSString *)accountID
      statusesMaxID:(NSString *)maxID
          completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/accounts/%@/statuses", accountID];
    if (maxID) {
        path = [path stringByAppendingFormat:@"?max_id=%@", maxID];
    }
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *statuses = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAStatus *status = [MAStatus statusFromDictionary:dict];
            if (status) [statuses addObject:status];
        }
        completion(statuses, nil);
    }];
}

#pragma mark - Status Actions

- (void)postStatus:(NSString *)content
       inReplyToID:(NSString *)inReplyToID
       visibility:(NSString *)visibility
       spoilerText:(NSString *)spoilerText
          sensitive:(BOOL)sensitive
        completion:(void (^)(MAStatus *, NSError *))completion {
    [self postStatus:content inReplyToID:inReplyToID visibility:visibility spoilerText:spoilerText sensitive:sensitive mediaIDs:nil pollOptions:nil pollExpiresIn:0 language:nil completion:completion];
}

- (void)postStatus:(NSString *)content
       inReplyToID:(NSString *)inReplyToID
       visibility:(NSString *)visibility
       spoilerText:(NSString *)spoilerText
          sensitive:(BOOL)sensitive
           mediaIDs:(NSArray *)mediaIDs
        completion:(void (^)(MAStatus *, NSError *))completion {

    [self postStatus:content inReplyToID:inReplyToID visibility:visibility spoilerText:spoilerText sensitive:sensitive mediaIDs:mediaIDs pollOptions:nil pollExpiresIn:0 language:nil completion:completion];
}

- (void)postStatus:(NSString *)content
       inReplyToID:(NSString *)inReplyToID
       visibility:(NSString *)visibility
       spoilerText:(NSString *)spoilerText
          sensitive:(BOOL)sensitive
           mediaIDs:(NSArray *)mediaIDs
        pollOptions:(NSArray *)pollOptions
       pollExpiresIn:(NSInteger)pollExpiresIn
           language:(NSString *)language
         completion:(void (^)(MAStatus *, NSError *))completion {

    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/statuses" method:@"POST"];

    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"status"] = content ?: @"";
    if (inReplyToID) body[@"in_reply_to_id"] = inReplyToID;
    if (visibility) body[@"visibility"] = visibility;
    if (spoilerText.length > 0) body[@"spoiler_text"] = spoilerText;
    body[@"sensitive"] = @(sensitive);
    if (mediaIDs.count > 0) body[@"media_ids"] = mediaIDs;
    if (language.length > 0) body[@"language"] = language;

    if (pollOptions.count > 0) {
        body[@"poll"] = @{
            @"options": pollOptions,
            @"expires_in": @(pollExpiresIn)
        };
    }

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [self performPOSTRequest:request bodyData:jsonData completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        completion([MAStatus statusFromDictionary:json], nil);
    }];
}

- (void)uploadMedia:(NSData *)imageData
           filename:(NSString *)filename
          mimeType:(NSString *)mimeType
       description:(NSString *)description
        completion:(void (^)(NSDictionary *, NSError *))completion {

    NSString *boundary = [[NSUUID UUID] UUIDString];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];

    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

    if (description.length > 0) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"description\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[description dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    NSURL *url = [NSURL URLWithString:@"/api/v2/media" relativeToURL:self.baseURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Mastonine/1.0" forHTTPHeaderField:@"User-Agent"];
    [request setHTTPBody:body];

    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, error); });
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
            NSError *apiError = [NSError errorWithDomain:@"com.mastonine.api" code:httpResponse.statusCode userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, apiError); });
            return;
        }
        NSError *jsonError = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        dispatch_async(dispatch_get_main_queue(), ^{ completion(json, nil); });
    }];
    [task resume];
}

- (void)boostStatus:(NSString *)statusID
         completion:(void (^)(MAStatus *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@/reblog", statusID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        completion([MAStatus statusFromDictionary:json[@"status"] ?: json], nil);
    }];
}

- (void)unboostStatus:(NSString *)statusID
           completion:(void (^)(MAStatus *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@/unreblog", statusID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        completion([MAStatus statusFromDictionary:json], nil);
    }];
}

- (void)favouriteStatus:(NSString *)statusID
             completion:(void (^)(MAStatus *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@/favourite", statusID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        completion([MAStatus statusFromDictionary:json], nil);
    }];
}

- (void)unfavouriteStatus:(NSString *)statusID
               completion:(void (^)(MAStatus *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@/unfavourite", statusID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        completion([MAStatus statusFromDictionary:json], nil);
    }];
}

#pragma mark - Status Context

- (void)fetchStatus:(NSString *)statusID
         completion:(void (^)(MAStatus *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@", statusID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        completion([MAStatus statusFromDictionary:json], nil);
    }];
}

- (void)fetchContextForStatus:(NSString *)statusID
                   completion:(void (^)(NSArray *, NSArray *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@/context", statusID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(@[], @[], error);
            return;
        }
        NSArray *ancestorsJson = json[@"ancestors"] ?: @[];
        NSArray *descendantsJson = json[@"descendants"] ?: @[];

        NSMutableArray *ancestors = [NSMutableArray array];
        for (NSDictionary *dict in ancestorsJson) {
            MAStatus *s = [MAStatus statusFromDictionary:dict];
            if (s) [ancestors addObject:s];
        }

        NSMutableArray *descendants = [NSMutableArray array];
        for (NSDictionary *dict in descendantsJson) {
            MAStatus *s = [MAStatus statusFromDictionary:dict];
            if (s) [descendants addObject:s];
        }

        completion(ancestors, descendants, nil);
    }];
}

#pragma mark - Search

- (void)searchQuery:(NSString *)query
         completion:(void (^)(NSDictionary *, NSError *))completion {
    NSString *encoded = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *path = [NSString stringWithFormat:@"/api/v2/search?q=%@", encoded];
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        completion(json, nil);
    }];
}

#pragma mark - Instance

- (void)fetchInstanceInfoWithCompletion:(void (^)(NSDictionary *, NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/instance" method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        completion(json, error);
    }];
}

#pragma mark - Account Settings

- (void)updateAccountSettings:(NSDictionary *)settings
                   completion:(void (^)(MAAccount *, NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/accounts/update_credentials" method:@"PATCH"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:settings options:0 error:nil];
    [self performPOSTRequest:request bodyData:jsonData completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        completion([MAAccount accountFromDictionary:json], nil);
    }];
}

#pragma mark - Follow / Unfollow

- (void)followAccount:(NSString *)accountID
           completion:(void (^)(MAAccount *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/accounts/%@/follow", accountID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) { completion(nil, error); return; }
        NSDictionary *rel = json[@"relationship"] ?: json;
        MAAccount *account = [MAAccount accountFromDictionary:rel];
        completion(account, nil);
    }];
}

- (void)unfollowAccount:(NSString *)accountID
             completion:(void (^)(MAAccount *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/accounts/%@/unfollow", accountID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) { completion(nil, error); return; }
        NSDictionary *rel = json[@"relationship"] ?: json;
        MAAccount *account = [MAAccount accountFromDictionary:rel];
        completion(account, nil);
    }];
}

#pragma mark - Block / Unblock

- (void)blockAccount:(NSString *)accountID
          completion:(void (^)(MAAccount *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/accounts/%@/block", accountID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) { completion(nil, error); return; }
        NSDictionary *rel = json[@"relationship"] ?: json;
        MAAccount *account = [MAAccount accountFromDictionary:rel];
        completion(account, nil);
    }];
}

- (void)unblockAccount:(NSString *)accountID
            completion:(void (^)(MAAccount *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/accounts/%@/unblock", accountID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) { completion(nil, error); return; }
        NSDictionary *rel = json[@"relationship"] ?: json;
        MAAccount *account = [MAAccount accountFromDictionary:rel];
        completion(account, nil);
    }];
}

#pragma mark - Mute / Unmute

- (void)muteAccount:(NSString *)accountID
         completion:(void (^)(MAAccount *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/accounts/%@/mute", accountID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) { completion(nil, error); return; }
        NSDictionary *rel = json[@"relationship"] ?: json;
        MAAccount *account = [MAAccount accountFromDictionary:rel];
        completion(account, nil);
    }];
}

- (void)unmuteAccount:(NSString *)accountID
           completion:(void (^)(MAAccount *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/accounts/%@/unmute", accountID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) { completion(nil, error); return; }
        NSDictionary *rel = json[@"relationship"] ?: json;
        MAAccount *account = [MAAccount accountFromDictionary:rel];
        completion(account, nil);
    }];
}

#pragma mark - Report

- (void)reportAccount:(NSString *)accountID
             statusIDs:(NSArray *)statusIDs
                reason:(NSString *)reason
            completion:(void (^)(NSError *))completion {
    NSString *path = @"/api/v1/reports";
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"account_id"] = accountID;
    if (statusIDs) body[@"status_ids"] = statusIDs;
    if (reason.length > 0) body[@"comment"] = reason;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [self performPOSTRequest:request bodyData:jsonData completion:^(id json, NSError *error) {
        completion(error);
    }];
}

#pragma mark - Delete Status

- (void)deleteStatus:(NSString *)statusID
          completion:(void (^)(NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@", statusID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"DELETE"];
    [self performRequest:request completion:^(id json, NSError *error) {
        completion(error);
    }];
}

#pragma mark - Bookmark / Unbookmark

- (void)bookmarkStatus:(NSString *)statusID
            completion:(void (^)(MAStatus *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@/bookmark", statusID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) { completion(nil, error); return; }
        completion([MAStatus statusFromDictionary:json], nil);
    }];
}

- (void)unbookmarkStatus:(NSString *)statusID
              completion:(void (^)(MAStatus *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@/unbookmark", statusID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) { completion(nil, error); return; }
        completion([MAStatus statusFromDictionary:json], nil);
    }];
}

#pragma mark - Pin / Unpin

- (void)pinStatus:(NSString *)statusID
       completion:(void (^)(MAStatus *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@/pin", statusID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) { completion(nil, error); return; }
        completion([MAStatus statusFromDictionary:json], nil);
    }];
}

- (void)unpinStatus:(NSString *)statusID
         completion:(void (^)(MAStatus *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@/unpin", statusID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        if (error || !json) { completion(nil, error); return; }
        completion([MAStatus statusFromDictionary:json], nil);
    }];
}

#pragma mark - Bookmarks

- (void)fetchBookmarksWithMaxID:(NSString *)maxID
                     completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = @"/api/v1/bookmarks";
    if (maxID) {
        path = [path stringByAppendingFormat:@"?max_id=%@", maxID];
    }
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *statuses = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAStatus *status = [MAStatus statusFromDictionary:dict];
            if (status) [statuses addObject:status];
        }
        completion(statuses, nil);
    }];
}

#pragma mark - Follow Requests

- (void)acceptFollowRequest:(NSString *)requestID
                 completion:(void (^)(NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/follow_requests/%@/authorize", requestID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        completion(error);
    }];
}

- (void)rejectFollowRequest:(NSString *)requestID
                 completion:(void (^)(NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/follow_requests/%@/reject", requestID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        completion(error);
    }];
}

#pragma mark - Relationship

- (void)fetchRelationshipForAccount:(NSString *)accountID
                         completion:(void (^)(NSDictionary *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/accounts/relationships?id[]=%@", accountID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]] || [json count] == 0) {
            completion(nil, error);
            return;
        }
        completion(json[0], nil);
    }];
}

#pragma mark - Followers / Following

- (void)fetchFollowers:(NSString *)accountID
                 maxID:(NSString *)maxID
            completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/accounts/%@/followers", accountID];
    if (maxID) {
        path = [path stringByAppendingFormat:@"?max_id=%@", maxID];
    }
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *accounts = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAAccount *account = [MAAccount accountFromDictionary:dict];
            if (account) [accounts addObject:account];
        }
        completion(accounts, nil);
    }];
}

- (void)fetchFollowing:(NSString *)accountID
                  maxID:(NSString *)maxID
             completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/accounts/%@/following", accountID];
    if (maxID) {
        path = [path stringByAppendingFormat:@"?max_id=%@", maxID];
    }
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *accounts = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAAccount *account = [MAAccount accountFromDictionary:dict];
            if (account) [accounts addObject:account];
        }
        completion(accounts, nil);
    }];
}

#pragma mark - Lists

- (void)fetchListsWithCompletion:(void (^)(NSArray *, NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/lists" method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *lists = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAList *list = [MAList listFromDictionary:dict];
            if (list) [lists addObject:list];
        }
        completion(lists, nil);
    }];
}

- (void)createListWithTitle:(NSString *)title completion:(void (^)(MAList *, NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/lists" method:@"POST"];
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"title"] = title ?: @"";
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [self performPOSTRequest:request bodyData:jsonData completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        completion([MAList listFromDictionary:json], nil);
    }];
}

- (void)deleteList:(NSString *)listID completion:(void (^)(NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/lists/%@", listID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"DELETE"];
    [self performRequest:request completion:^(id json, NSError *error) {
        completion(error);
    }];
}

- (void)fetchListTimeline:(NSString *)listID maxID:(NSString *)maxID completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/timelines/list/%@", listID];
    if (maxID) {
        path = [path stringByAppendingFormat:@"?max_id=%@", maxID];
    }
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *statuses = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAStatus *status = [MAStatus statusFromDictionary:dict];
            if (status) [statuses addObject:status];
        }
        completion(statuses, nil);
    }];
}

- (void)fetchListAccounts:(NSString *)listID maxID:(NSString *)maxID completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/lists/%@/accounts", listID];
    if (maxID) {
        path = [path stringByAppendingFormat:@"?max_id=%@", maxID];
    }
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *accounts = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAAccount *account = [MAAccount accountFromDictionary:dict];
            if (account) [accounts addObject:account];
        }
        completion(accounts, nil);
    }];
}

- (void)addAccountsToList:(NSString *)listID accountIDs:(NSArray *)accountIDs completion:(void (^)(NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/lists/%@/accounts", listID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"account_ids"] = accountIDs;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [self performPOSTRequest:request bodyData:jsonData completion:^(id json, NSError *error) {
        completion(error);
    }];
}

- (void)removeAccountsFromList:(NSString *)listID accountIDs:(NSArray *)accountIDs completion:(void (^)(NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/lists/%@/accounts", listID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"DELETE"];
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"account_ids"] = accountIDs;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [request setHTTPBody:jsonData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [self performRequest:request completion:^(id json, NSError *error) {
        completion(error);
    }];
}

#pragma mark - Explore / Trending

- (void)fetchTrendingTagsWithCompletion:(void (^)(NSArray *, NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/trends/tags" method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        completion(json, nil);
    }];
}

- (void)fetchSuggestedAccountsWithCompletion:(void (^)(NSArray *, NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v2/suggestions" method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]] || [(NSArray *)json count] == 0) {
            NSMutableURLRequest *fallback = [self requestForPath:@"/api/v1/suggestions" method:@"GET"];
            [self performRequest:fallback completion:^(id json2, NSError *error2) {
                if (error2 || ![json2 isKindOfClass:[NSArray class]]) {
                    completion(@[], error2 ?: error);
                    return;
                }
                [self _parseSuggestedAccounts:json2 completion:completion];
            }];
            return;
        }
        [self _parseSuggestedAccounts:json completion:completion];
    }];
}

- (void)_parseSuggestedAccounts:(NSArray *)json completion:(void (^)(NSArray *, NSError *))completion {
    NSMutableArray *accounts = [NSMutableArray array];
    for (NSDictionary *item in json) {
        NSDictionary *accountDict = item[@"account"] ?: item;
        MAAccount *account = [MAAccount accountFromDictionary:accountDict];
        if (account) [accounts addObject:account];
    }
    completion(accounts, nil);
}

- (void)fetchTrendingStatusesWithCompletion:(void (^)(NSArray *, NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/trends/statuses" method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *statuses = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAStatus *status = [MAStatus statusFromDictionary:dict];
            if (status) [statuses addObject:status];
        }
        completion(statuses, nil);
    }];
}

#pragma mark - Polls

- (void)voteOnPoll:(NSString *)pollID choices:(NSArray *)choices completion:(void (^)(MAPoll *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/polls/%@/votes", pollID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"choices"] = choices;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [self performPOSTRequest:request bodyData:jsonData completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        completion([MAPoll pollFromDictionary:json], nil);
    }];
}

#pragma mark - Favourites

- (void)fetchFavouritesWithMaxID:(NSString *)maxID completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = @"/api/v1/favourites";
    if (maxID) {
        path = [NSString stringWithFormat:@"%@?max_id=%@", path, maxID];
    }
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *statuses = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAStatus *status = [MAStatus statusFromDictionary:dict];
            if (status) [statuses addObject:status];
        }
        completion(statuses, nil);
    }];
}

#pragma mark - Reblogged/Favourited By

- (void)fetchRebloggedByStatusID:(NSString *)statusID
                           maxID:(NSString *)maxID
                      completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@/reblogged_by", statusID];
    if (maxID.length > 0) {
        path = [path stringByAppendingFormat:@"?max_id=%@", maxID];
    }
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *accounts = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAAccount *account = [MAAccount accountFromDictionary:dict];
            if (account) [accounts addObject:account];
        }
        completion(accounts, nil);
    }];
}

- (void)fetchFavouritedByStatusID:(NSString *)statusID
                            maxID:(NSString *)maxID
                       completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@/favourited_by", statusID];
    if (maxID.length > 0) {
        path = [path stringByAppendingFormat:@"?max_id=%@", maxID];
    }
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *accounts = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAAccount *account = [MAAccount accountFromDictionary:dict];
            if (account) [accounts addObject:account];
        }
        completion(accounts, nil);
    }];
}

#pragma mark - Edit Status

- (void)editStatus:(NSString *)statusID content:(NSString *)content spoilerText:(NSString *)spoilerText completion:(void (^)(MAStatus *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@", statusID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"PUT"];
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"status"] = content;
    if (spoilerText.length > 0) {
        body[@"spoiler_text"] = spoilerText;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [self performPOSTRequest:request bodyData:jsonData completion:^(id json, NSError *error) {
        if (error || !json) {
            completion(nil, error);
            return;
        }
        completion([MAStatus statusFromDictionary:json], nil);
    }];
}

#pragma mark - Edit History

- (void)fetchEditHistoryForStatus:(NSString *)statusID
                       completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/statuses/%@/history", statusID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        completion(json, nil);
    }];
}

#pragma mark - Followed Hashtags

- (void)fetchFollowedHashtagsWithCompletion:(void (^)(NSArray *, NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/followed_tags" method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        completion(json, nil);
    }];
}

- (void)unfollowHashtag:(NSString *)name completion:(void (^)(NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/tags/%@/unfollow", name];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        completion(error);
    }];
}

- (void)followHashtag:(NSString *)name completion:(void (^)(NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/tags/%@/follow", name];
    NSMutableURLRequest *request = [self requestForPath:path method:@"POST"];
    [self performPOSTRequest:request bodyData:nil completion:^(id json, NSError *error) {
        completion(error);
    }];
}

#pragma mark - Blocked Users

- (void)fetchBlockedAccountsWithMaxID:(NSString *)maxID
                           completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = @"/api/v1/accounts/blocked";
    if (maxID.length > 0) {
        path = [path stringByAppendingFormat:@"?max_id=%@", maxID];
    }
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *accounts = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAAccount *account = [MAAccount accountFromDictionary:dict];
            if (account) [accounts addObject:account];
        }
        completion(accounts, nil);
    }];
}

#pragma mark - Muted Users

- (void)fetchMutedAccountsWithMaxID:(NSString *)maxID
                         completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = @"/api/v1/accounts/muted";
    if (maxID.length > 0) {
        path = [path stringByAppendingFormat:@"?max_id=%@", maxID];
    }
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *accounts = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAAccount *account = [MAAccount accountFromDictionary:dict];
            if (account) [accounts addObject:account];
        }
        completion(accounts, nil);
    }];
}

#pragma mark - Lists (Paginated)

- (void)fetchListsMaxID:(NSString *)maxID
             completion:(void (^)(NSArray *, NSError *))completion {
    NSString *path = @"/api/v1/lists";
    if (maxID.length > 0) {
        path = [path stringByAppendingFormat:@"?max_id=%@", maxID];
    }
    NSMutableURLRequest *request = [self requestForPath:path method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            completion(@[], error);
            return;
        }
        NSMutableArray *lists = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            MAList *list = [MAList listFromDictionary:dict];
            if (list) [lists addObject:list];
        }
        completion(lists, nil);
    }];
}

#pragma mark - Push Subscription

- (void)fetchPushSubscriptionWithCompletion:(void (^)(NSDictionary *, NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/push/subscription" method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        completion(json, nil);
    }];
}

- (void)updatePushSubscriptionAlerts:(NSDictionary *)alerts
                          completion:(void (^)(NSDictionary *, NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/push/subscription" method:@"POST"];
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"data[alerts][follow]"] = @([alerts[@"follow"] boolValue]);
    body[@"data[alerts][favourite]"] = @([alerts[@"favourite"] boolValue]);
    body[@"data[alerts][reblog]"] = @([alerts[@"reblog"] boolValue]);
    body[@"data[alerts][mention]"] = @([alerts[@"mention"] boolValue]);
    body[@"data[alerts][poll]"] = @([alerts[@"poll"] boolValue]);
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [self performPOSTRequest:request bodyData:jsonData completion:^(id json, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        completion(json, nil);
    }];
}

- (void)deletePushSubscriptionWithCompletion:(void (^)(NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/push/subscription" method:@"DELETE"];
    [self performRequest:request completion:^(id json, NSError *error) {
        completion(error);
    }];
}

@end
