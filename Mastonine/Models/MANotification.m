#import "MANotification.h"
#import "MAStatus.h"
#import "MAAccount.h"

@implementation MANotification

+ (instancetype)notificationFromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;

    MANotification *notification = [[MANotification alloc] init];
    notification.notificationID = [dict[@"id"] description];
    notification.account = [MAAccount accountFromDictionary:dict[@"account"]];

    NSString *type = dict[@"type"] ?: @"";
    if ([type isEqualToString:@"mention"]) {
        notification.type = MANotificationTypeMention;
    } else if ([type isEqualToString:@"reblog"]) {
        notification.type = MANotificationTypeReblog;
    } else if ([type isEqualToString:@"favourite"]) {
        notification.type = MANotificationTypeFavourite;
    } else if ([type isEqualToString:@"follow"]) {
        notification.type = MANotificationTypeFollow;
    } else if ([type isEqualToString:@"follow_request"]) {
        notification.type = MANotificationTypeFollowRequest;
    } else {
        notification.type = MANotificationTypeUnknown;
    }

    if (dict[@"status"] && [dict[@"status"] isKindOfClass:[NSDictionary class]]) {
        notification.status = [MAStatus statusFromDictionary:dict[@"status"]];
    }

    NSString *createdAt = dict[@"created_at"];
    if (createdAt) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        notification.createdAt = [formatter dateFromString:createdAt];
    }

    return notification;
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
