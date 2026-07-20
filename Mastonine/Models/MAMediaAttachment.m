#import "MAMediaAttachment.h"

@implementation MAMediaAttachment

+ (instancetype)attachmentFromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;

    MAMediaAttachment *att = [[MAMediaAttachment alloc] init];
    att.attachmentID = [dict[@"id"] description];
    att.url = dict[@"url"] ?: @"";
    att.previewURL = dict[@"preview_url"] ?: @"";
    att.remoteURL = dict[@"remote_url"] ?: @"";
    att.textURL = dict[@"text_url"] ?: @"";
    att.descriptionText = dict[@"description"] ?: @"";
    att.blurhash = dict[@"blurhash"] ?: @"";

    NSString *type = dict[@"type"] ?: @"";
    if ([type isEqualToString:@"image"]) {
        att.type = MAMediaTypeImage;
    } else if ([type isEqualToString:@"video"]) {
        att.type = MAMediaTypeVideo;
    } else if ([type isEqualToString:@"gifv"]) {
        att.type = MAMediaTypeGIFV;
    } else if ([type isEqualToString:@"audio"]) {
        att.type = MAMediaTypeAudio;
    } else {
        att.type = MAMediaTypeUnknown;
    }

    return att;
}

@end
