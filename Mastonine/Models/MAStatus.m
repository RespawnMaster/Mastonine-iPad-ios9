#import "MAStatus.h"
#import "MAAccount.h"
#import "MAMediaAttachment.h"
#import "MAPoll.h"

@implementation MAStatus

+ (instancetype)statusFromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;

    MAStatus *status = [[MAStatus alloc] init];

    NSDictionary *reblog = dict[@"reblog"];
    if (reblog && [reblog isKindOfClass:[NSDictionary class]]) {
        status.reblogID = [dict[@"id"] description];
        status.reblogAccount = [MAAccount accountFromDictionary:dict[@"account"]];
        dict = reblog;
    }

    status.statusID = [dict[@"id"] description];
    status.content = dict[@"content"] ?: @"";
    status.account = [MAAccount accountFromDictionary:dict[@"account"]];
    status.reblogsCount = [dict[@"reblogs_count"] integerValue];
    status.favouritesCount = [dict[@"favourites_count"] integerValue];
    status.repliesCount = [dict[@"replies_count"] integerValue];
    status.reblogged = [dict[@"reblogged"] boolValue];
    status.favourited = [dict[@"favourited"] boolValue];
    status.bookmarked = [dict[@"bookmarked"] boolValue];
    status.visibility = dict[@"visibility"] ?: @"public";
    status.spoilerText = dict[@"spoiler_text"] ?: @"";
    status.sensitive = [dict[@"sensitive"] boolValue];
    status.inReplyToID = [dict[@"in_reply_to_id"] description];
    status.inReplyToAccountID = [dict[@"in_reply_to_account_id"] description];
    status.url = dict[@"url"] ?: @"";

    NSArray *mediaArray = dict[@"media_attachments"];
    if ([mediaArray isKindOfClass:[NSArray class]] && mediaArray.count > 0) {
        NSMutableArray *attachments = [NSMutableArray array];
        for (NSDictionary *mediaDict in mediaArray) {
            MAMediaAttachment *att = [MAMediaAttachment attachmentFromDictionary:mediaDict];
            if (att) [attachments addObject:att];
        }
        status.mediaAttachments = attachments;
    } else {
        status.mediaAttachments = @[];
    }

    NSDictionary *pollDict = dict[@"poll"];
    if ([pollDict isKindOfClass:[NSDictionary class]]) {
        status.poll = [MAPoll pollFromDictionary:pollDict];
    }

    NSString *createdAt = dict[@"created_at"];
    if (createdAt) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        status.createdAt = [formatter dateFromString:createdAt];
    }

    return status;
}

- (MAStatus *)boostedStatus {
    if (self.reblogID) {
        return self;
    }
    return self;
}

- (NSString *)relativeTimeString {
    if (!self.createdAt) return @"";

    NSTimeInterval interval = -[self.createdAt timeIntervalSinceNow];

    if (interval < 60) return @"now";
    if (interval < 3600) return [NSString stringWithFormat:@"%dm", (int)(interval / 60)];
    if (interval < 86400) return [NSString stringWithFormat:@"%dh", (int)(interval / 3600)];
    if (interval < 604800) return [NSString stringWithFormat:@"%dd", (int)(interval / 86400)];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MMM d";
    return [formatter stringFromDate:self.createdAt];
}

@end
