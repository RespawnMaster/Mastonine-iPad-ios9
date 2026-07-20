#import "MAPoll.h"

@implementation MAPoll
+ (instancetype)pollFromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    MAPoll *poll = [[MAPoll alloc] init];
    poll.pollID = [dict[@"id"] description];
    poll.expired = [dict[@"expired"] boolValue];
    poll.multiple = [dict[@"multiple"] boolValue];
    poll.votesCount = [dict[@"votes_count"] integerValue];
    poll.options = dict[@"options"] ?: @[];
    poll.ownVotes = dict[@"own_votes"] ?: @[];

    NSString *expiresAt = dict[@"expires_at"];
    if (expiresAt && ![expiresAt isKindOfClass:[NSNull class]]) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        fmt.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        fmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        poll.expiresAt = [fmt dateFromString:expiresAt];
    }
    return poll;
}
@end
