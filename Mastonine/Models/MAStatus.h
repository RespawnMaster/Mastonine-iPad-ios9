#import <Foundation/Foundation.h>

@class MAAccount;
@class MAPoll;

@interface MAStatus : NSObject

@property (nonatomic, copy) NSString *statusID;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, strong) MAAccount *account;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, assign) NSInteger reblogsCount;
@property (nonatomic, assign) NSInteger favouritesCount;
@property (nonatomic, assign) NSInteger repliesCount;
@property (nonatomic, assign) BOOL reblogged;
@property (nonatomic, assign) BOOL favourited;
@property (nonatomic, assign) BOOL bookmarked;
@property (nonatomic, copy) NSString *visibility;
@property (nonatomic, copy) NSString *spoilerText;
@property (nonatomic, assign) BOOL sensitive;
@property (nonatomic, copy) NSString *reblogID;
@property (nonatomic, strong) MAAccount *reblogAccount;
@property (nonatomic, copy) NSString *inReplyToID;
@property (nonatomic, copy) NSString *inReplyToAccountID;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) NSArray *mediaAttachments;
@property (nonatomic, strong) MAPoll *poll;

+ (instancetype)statusFromDictionary:(NSDictionary *)dict;
- (MAStatus *)boostedStatus;
- (NSString *)relativeTimeString;

@end
