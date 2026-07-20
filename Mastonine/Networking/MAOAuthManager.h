#import <Foundation/Foundation.h>

@interface MAOAuthManager : NSObject

+ (void)registerApplicationWithInstance:(NSString *)instance
                             clientName:(NSString *)clientName
                             redirectURI:(NSString *)redirectURI
                             scopes:(NSString *)scopes
                             completion:(void (^)(NSString *clientID, NSString *clientSecret, NSURL *authURL, NSError *error))completion;

+ (void)authorizeApplicationWithClientID:(NSString *)clientID
                            clientSecret:(NSString *)clientSecret
                                instance:(NSString *)instance
                                    code:(NSString *)code
                            redirectURI:(NSString *)redirectURI
                              completion:(void (^)(NSString *accessToken, NSError *error))completion;

+ (NSURL *)oauthAuthorizationURLForInstance:(NSString *)instance
                                   clientID:(NSString *)clientID
                                redirectURI:(NSString *)redirectURI
                                      scope:(NSString *)scope;

@end
