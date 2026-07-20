#import "MAFilterManager.h"
#import "MAAPIClient.h"

static NSString * const kContentFiltersKey = @"content_filters";

@interface MAFilterManager ()

@property (nonatomic, strong) NSMutableArray *filters;
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation MAFilterManager

+ (instancetype)sharedManager {
    static MAFilterManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[MAFilterManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 30;
        config.timeoutIntervalForResource = 60;
        _session = [NSURLSession sessionWithConfiguration:config];
        _filters = [[[NSUserDefaults standardUserDefaults] arrayForKey:kContentFiltersKey] mutableCopy] ?: [NSMutableArray array];
    }
    return self;
}

#pragma mark - Request Helpers

- (NSMutableURLRequest *)requestForPath:(NSString *)path method:(NSString *)method {
    MAAPIClient *client = [MAAPIClient sharedClient];
    NSURL *url = [NSURL URLWithString:path relativeToURL:client.baseURL];
    if (!url) url = [NSURL URLWithString:[client.baseURL.absoluteString stringByAppendingString:path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"Mastonine/1.0" forHTTPHeaderField:@"User-Agent"];

    if (client.accessToken) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", client.accessToken]
       forHTTPHeaderField:@"Authorization"];
    }

    return request;
}

- (void)performRequest:(NSMutableURLRequest *)request
            completion:(void (^)(id, NSError *))completion {
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
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

#pragma mark - Persistence

- (void)saveFilters {
    [[NSUserDefaults standardUserDefaults] setObject:self.filters forKey:kContentFiltersKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Load Filters

- (void)loadFiltersWithCompletion:(void (^)(void))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/filters" method:@"GET"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error || ![json isKindOfClass:[NSArray class]]) {
            if (completion) completion();
            return;
        }
        self.filters = [json mutableCopy];
        [self saveFilters];
        if (completion) completion();
    }];
}

#pragma mark - Filtering Logic

- (BOOL)shouldFilterStatusWithContent:(NSString *)content spoilerText:(NSString *)spoilerText {
    NSString *lowerContent = [content lowercaseString];
    NSString *lowerSpoiler = [spoilerText lowercaseString];

    for (NSDictionary *filter in self.filters) {
        NSString *phrase = filter[@"phrase"];
        if (!phrase || ![phrase isKindOfClass:[NSString class]] || phrase.length == 0) continue;

        NSString *lowerPhrase = [phrase lowercaseString];

        if (lowerContent.length > 0 && [lowerContent containsString:lowerPhrase]) {
            return YES;
        }

        if (lowerSpoiler.length > 0 && [lowerSpoiler containsString:lowerPhrase]) {
            return YES;
        }
    }

    return NO;
}

#pragma mark - Active Filters

- (NSArray *)activeFilters {
    return [self.filters copy];
}

#pragma mark - Add Filter

- (void)addFilterWithPhrase:(NSString *)phrase
                    context:(NSArray *)contexts
           expiresInSeconds:(NSInteger)expires
                 completion:(void (^)(NSError *))completion {
    NSMutableURLRequest *request = [self requestForPath:@"/api/v1/filters" method:@"POST"];

    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"phrase"] = phrase ?: @"";
    body[@"context"] = contexts ?: @[@"home"];
    if (expires > 0) {
        body[@"expires_in"] = @(expires);
    }

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [self performPOSTRequest:request bodyData:jsonData completion:^(id json, NSError *error) {
        if (error || !json) {
            if (completion) completion(error);
            return;
        }
        if ([json isKindOfClass:[NSDictionary class]]) {
            [self.filters addObject:json];
            [self saveFilters];
        }
        if (completion) completion(nil);
    }];
}

#pragma mark - Delete Filter

- (void)deleteFilterWithID:(NSString *)filterID
                completion:(void (^)(NSError *))completion {
    NSString *path = [NSString stringWithFormat:@"/api/v1/filters/%@", filterID];
    NSMutableURLRequest *request = [self requestForPath:path method:@"DELETE"];
    [self performRequest:request completion:^(id json, NSError *error) {
        if (error) {
            if (completion) completion(error);
            return;
        }
        NSMutableArray *updated = [NSMutableArray array];
        for (NSDictionary *filter in self.filters) {
            NSString *fid = filter[@"id"];
            if (![fid isEqualToString:filterID]) {
                [updated addObject:filter];
            }
        }
        self.filters = updated;
        [self saveFilters];
        if (completion) completion(nil);
    }];
}

@end
