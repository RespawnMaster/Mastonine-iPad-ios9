#import <Foundation/Foundation.h>

@interface MAAccount : NSObject <NSCoding>

@property (nonatomic, copy) NSString *accountID;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *accountDescription;
@property (nonatomic, copy) NSString *avatarURLString;
@property (nonatomic, copy) NSString *headerURLString;
@property (nonatomic, copy) NSString *note;
@property (nonatomic, assign) NSInteger statusesCount;
@property (nonatomic, assign) NSInteger followingCount;
@property (nonatomic, assign) NSInteger followersCount;
@property (nonatomic, assign) BOOL isLocked;
@property (nonatomic, assign) BOOL following;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) NSArray *fields;
@property (nonatomic, strong) NSArray *featuredTags;
@property (nonatomic, copy) NSString *domain;

+ (instancetype)accountFromDictionary:(NSDictionary *)dict;
- (NSURL *)avatarURL;
- (NSURL *)headerURL;
- (NSString *)displayNameOrUsername;

@end
