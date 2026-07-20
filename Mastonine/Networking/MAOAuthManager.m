#import "MAOAuthManager.h"

@implementation MAOAuthManager

+ (void)registerApplicationWithInstance:(NSString *)instance
                             clientName:(NSString *)clientName
                             redirectURI:(NSString *)redirectURI
                             scopes:(NSString *)scopes
                             completion:(void (^)(NSString *, NSString *, NSURL *, NSError *))completion {

    NSString *baseURL = instance;
    if (![baseURL hasPrefix:@"http"]) {
        baseURL = [@"https://" stringByAppendingString:baseURL];
    }

    NSString *path = [NSString stringWithFormat:@"%@/api/v1/apps", baseURL];
    NSURL *url = [NSURL URLWithString:path];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Mastonine/1.0" forHTTPHeaderField:@"User-Agent"];

    NSDictionary *body = @{
        @"client_name": clientName ?: @"Mastonine",
        @"redirect_uris": redirectURI ?: @"mastonine://oauth/callback",
        @"scopes": scopes ?: @"read write follow",
    };

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    request.HTTPBody = jsonData;

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *responseBody = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;

        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, nil, error);
            });
            return;
        }

        if (httpResponse.statusCode == 429) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, nil, [NSError errorWithDomain:@"com.mastonine.oauth" code:-4 userInfo:@{NSLocalizedDescriptionKey: @"Rate limited by server. Please wait a minute and try again."}]);
            });
            return;
        }

        if (httpResponse.statusCode >= 400) {
            NSString *detail = responseBody ?: [NSString stringWithFormat:@"HTTP %ld", (long)httpResponse.statusCode];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, nil, [NSError errorWithDomain:@"com.mastonine.oauth" code:httpResponse.statusCode userInfo:@{NSLocalizedDescriptionKey: detail}]);
            });
            return;
        }

        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError || !json) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, nil, jsonError ?: [NSError errorWithDomain:@"com.mastonine.oauth" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}]);
            });
            return;
        }

        NSString *clientID = json[@"client_id"];
        NSString *clientSecret = json[@"client_secret"];

        if (!clientID || !clientSecret) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *detail = [NSString stringWithFormat:@"Server response keys: %@", [json allKeys]];
                completion(nil, nil, nil, [NSError errorWithDomain:@"com.mastonine.oauth" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"Missing client credentials", @"responseBody": detail}]);
            });
            return;
        }

        NSURL *authURL = [MAOAuthManager oauthAuthorizationURLForInstance:instance
                                                                clientID:clientID
                                                             redirectURI:redirectURI
                                                                   scope:scopes ?: @"read write follow"];

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(clientID, clientSecret, authURL, nil);
        });
    }];
    [task resume];
}

+ (NSString *)encodeFormValue:(NSString *)value {
    return [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

+ (void)authorizeApplicationWithClientID:(NSString *)clientID
                            clientSecret:(NSString *)clientSecret
                                instance:(NSString *)instance
                                    code:(NSString *)code
                            redirectURI:(NSString *)redirectURI
                              completion:(void (^)(NSString *, NSError *))completion {

    NSString *baseURL = instance;
    if (![baseURL hasPrefix:@"http"]) {
        baseURL = [@"https://" stringByAppendingString:baseURL];
    }
    baseURL = [baseURL stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];

    NSString *path = [NSString stringWithFormat:@"%@/oauth/token", baseURL];
    NSURL *url = [NSURL URLWithString:path];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Mastonine/1.0" forHTTPHeaderField:@"User-Agent"];

    NSString *encodedClientID = [self encodeFormValue:clientID];
    NSString *encodedClientSecret = [self encodeFormValue:clientSecret];
    NSString *encodedCode = [self encodeFormValue:code];
    NSString *encodedRedirect = [self encodeFormValue:redirectURI ?: @"mastonine://oauth/callback"];

    NSString *bodyString = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&grant_type=authorization_code&code=%@&redirect_uri=%@",
                            encodedClientID, encodedClientSecret, encodedCode, encodedRedirect];
    request.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }

        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError || !json) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, jsonError ?: [NSError errorWithDomain:@"com.mastonine.oauth" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}]);
            });
            return;
        }

        NSString *accessToken = json[@"access_token"];
        if (!accessToken) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, [NSError errorWithDomain:@"com.mastonine.oauth" code:-3 userInfo:@{NSLocalizedDescriptionKey: @"No access token"}]);
            });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(accessToken, nil);
        });
    }];
    [task resume];
}

+ (NSURL *)oauthAuthorizationURLForInstance:(NSString *)instance
                                   clientID:(NSString *)clientID
                                redirectURI:(NSString *)redirectURI
                                      scope:(NSString *)scope {

    NSString *baseURL = instance;
    if (![baseURL hasPrefix:@"http"]) {
        baseURL = [@"https://" stringByAppendingString:baseURL];
    }

    NSString *redirect = redirectURI ?: @"mastonine://oauth/callback";
    NSString *encodedRedirect = [redirect stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *encodedScope = [scope stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSString *urlString = [NSString stringWithFormat:@"%@/oauth/authorize?client_id=%@&redirect_uri=%@&scope=%@&response_type=code",
                           baseURL, clientID, encodedRedirect, encodedScope];

    return [NSURL URLWithString:urlString];
}

@end
