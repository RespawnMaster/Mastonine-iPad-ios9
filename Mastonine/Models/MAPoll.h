#import <Foundation/Foundation.h>

@interface MAPoll : NSObject
@property (nonatomic, copy) NSString *pollID;
@property (nonatomic, copy) NSDate *expiresAt;
@property (nonatomic, assign) BOOL expired;
@property (nonatomic, assign) BOOL multiple;
@property (nonatomic, assign) NSInteger votesCount;
@property (nonatomic, strong) NSArray *options;
@property (nonatomic, strong) NSArray *ownVotes;
+ (instancetype)pollFromDictionary:(NSDictionary *)dict;
@end
