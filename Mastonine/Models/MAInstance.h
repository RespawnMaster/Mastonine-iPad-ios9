#import <Foundation/Foundation.h>

@interface MAInstance : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *domain;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, assign) NSInteger userCount;
@property (nonatomic, assign) NSInteger statusCount;
@property (nonatomic, assign) NSInteger domainCount;
@property (nonatomic, assign) BOOL registrations;
@property (nonatomic, copy) NSString *descriptionText;

+ (instancetype)instanceFromDictionary:(NSDictionary *)dict;
+ (instancetype)instanceFromDomain:(NSString *)domain;

@end
