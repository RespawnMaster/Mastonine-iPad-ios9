#import "MASpotlightIndexer.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import "MAStatus.h"
#import "MAAccount.h"
#import "MAAPIClient.h"

static NSString * const kUTTypeUTF8PlainText = @"public.utf8-plain-text";

@implementation MASpotlightIndexer

+ (void)indexStatus:(MAStatus *)status {
    if (!status || !status.statusID) return;

    NSString *plainText = status.content;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<[^>]+>" options:0 error:nil];
    plainText = [regex stringByReplacingMatchesInString:plainText options:0 range:NSMakeRange(0, plainText.length) withTemplate:@" "];
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+" options:0 error:nil];
    plainText = [regex stringByReplacingMatchesInString:plainText options:0 range:NSMakeRange(0, plainText.length) withTemplate:@" "];
    plainText = [plainText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (plainText.length == 0) return;

    CSSearchableItemAttributeSet *attrs = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeUTF8PlainText];
    attrs.title = [NSString stringWithFormat:@"@%@", status.account.username];
    attrs.contentDescription = plainText;
    attrs.keywords = @[@"mastodon", @"toot", @"post"];

    NSString *identifier = [NSString stringWithFormat:@"mastonine-status-%@", status.statusID];
    CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:identifier
                                                               domainIdentifier:@"mastonine-statuses"
                                                                   attributeSet:attrs];

    [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[item] completionHandler:^(NSError *error) {
    }];
}

+ (void)indexAccount:(MAAccount *)account {
    if (!account || !account.accountID) return;

    CSSearchableItemAttributeSet *attrs = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeUTF8PlainText];
    attrs.title = [account displayNameOrUsername];
    attrs.contentDescription = [NSString stringWithFormat:@"@%@", account.username];

    NSString *identifier = [NSString stringWithFormat:@"mastonine-account-%@", account.accountID];
    CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:identifier
                                                               domainIdentifier:@"mastonine-accounts"
                                                                   attributeSet:attrs];

    [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[item] completionHandler:^(NSError *error) {
    }];
}

+ (void)removeStatusWithID:(NSString *)statusID {
    if (!statusID) return;
    NSString *identifier = [NSString stringWithFormat:@"mastonine-status-%@", statusID];
    [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithIdentifiers:@[identifier] completionHandler:nil];
}

+ (void)removeAccountWithID:(NSString *)accountID {
    if (!accountID) return;
    NSString *identifier = [NSString stringWithFormat:@"mastonine-account-%@", accountID];
    [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithIdentifiers:@[identifier] completionHandler:nil];
}

+ (void)removeAll {
    [[CSSearchableIndex defaultSearchableIndex] deleteAllSearchableItemsWithCompletionHandler:nil];
}

@end
