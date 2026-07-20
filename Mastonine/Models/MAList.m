#import "MAList.h"

@implementation MAList
+ (instancetype)listFromDictionary:(NSDictionary *)dict {
    if (!dict) return nil;
    MAList *list = [[MAList alloc] init];
    list.listID = [dict[@"id"] description];
    list.title = dict[@"title"] ?: @"";
    return list;
}
@end
