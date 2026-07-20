#import "MAInstance.h"

@implementation MAInstance

+ (instancetype)instanceFromDictionary:(NSDictionary *)dict {
    if (!dict) return nil;
    MAInstance *instance = [[MAInstance alloc] init];
    instance.name = dict[@"title"] ?: @"";
    instance.version = dict[@"version"] ?: @"";
    instance.userCount = [dict[@"stats"][@"users_count"] integerValue];
    instance.statusCount = [dict[@"stats"][@"status_count"] integerValue];
    instance.domainCount = [dict[@"stats"][@"domain_count"] integerValue];
    instance.registrations = [dict[@"registrations"] boolValue];
    instance.descriptionText = dict[@"description"] ?: @"";
    return instance;
}

+ (instancetype)instanceFromDomain:(NSString *)domain {
    MAInstance *instance = [[MAInstance alloc] init];
    instance.domain = domain;
    instance.name = domain;
    return instance;
}

@end
