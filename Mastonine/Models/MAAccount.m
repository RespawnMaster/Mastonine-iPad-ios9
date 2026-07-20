#import "MAAccount.h"

@implementation MAAccount

+ (instancetype)accountFromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;

    MAAccount *account = [[MAAccount alloc] init];
    account.accountID = [dict[@"id"] description];
    account.username = dict[@"username"] ?: @"";
    account.displayName = dict[@"display_name"] ?: @"";
    account.accountDescription = dict[@"note"] ?: @"";
    account.note = dict[@"note"] ?: @"";
    account.avatarURLString = dict[@"avatar"] ?: @"";
    account.headerURLString = dict[@"header"] ?: @"";
    account.isLocked = [dict[@"locked"] boolValue];
    account.url = dict[@"url"] ?: @"";

    NSDictionary *counts = dict[@"statuses_count"];
    if ([counts isKindOfClass:[NSDictionary class]]) {
        account.statusesCount = [counts[@"statuses"] integerValue];
        account.followingCount = [counts[@"following"] integerValue];
        account.followersCount = [counts[@"followers"] integerValue];
    } else {
        account.statusesCount = [dict[@"statuses_count"] integerValue];
        account.followingCount = [dict[@"following_count"] integerValue];
        account.followersCount = [dict[@"followers_count"] integerValue];
    }

    if ([dict[@"fields"] isKindOfClass:[NSArray class]]) {
        NSMutableArray *parsedFields = [NSMutableArray array];
        for (NSDictionary *fieldDict in dict[@"fields"]) {
            if ([fieldDict isKindOfClass:[NSDictionary class]] && fieldDict[@"name"]) {
                [parsedFields addObject:@{@"name": fieldDict[@"name"] ?: @"", @"value": fieldDict[@"value"] ?: @""}];
            }
        }
        account.fields = parsedFields;
    }

    if ([dict[@"featured_tags"] isKindOfClass:[NSArray class]]) {
        NSMutableArray *tags = [NSMutableArray array];
        for (NSDictionary *tagDict in dict[@"featured_tags"]) {
            if ([tagDict isKindOfClass:[NSDictionary class]] && tagDict[@"name"]) {
                [tags addObject:tagDict[@"name"]];
            }
        }
        account.featuredTags = tags;
    }

    if ([dict[@"source"] isKindOfClass:[NSDictionary class]]) {
        NSString *domain = dict[@"source"][@"domain"];
        if ([domain isKindOfClass:[NSString class]] && domain.length > 0) {
            account.domain = domain;
        }
    }

    if (!account.domain && account.url.length > 0) {
        NSURL *url = [NSURL URLWithString:account.url];
        account.domain = url.host;
    }

    return account;
}

- (NSURL *)avatarURL {
    NSString *urlStr = self.avatarURLString;
    if (!urlStr || urlStr.length == 0) return nil;

    if ([urlStr hasPrefix:@"//"]) {
        urlStr = [@"https:" stringByAppendingString:urlStr];
    }

    return [NSURL URLWithString:urlStr];
}

- (NSURL *)headerURL {
    NSString *urlStr = self.headerURLString;
    if (!urlStr || urlStr.length == 0) return nil;

    if ([urlStr hasPrefix:@"//"]) {
        urlStr = [@"https:" stringByAppendingString:urlStr];
    }

    return [NSURL URLWithString:urlStr];
}

- (NSString *)displayNameOrUsername {
    if (self.displayName.length > 0) {
        return self.displayName;
    }
    return [NSString stringWithFormat:@"@%@", self.username];
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.accountID forKey:@"accountID"];
    [coder encodeObject:self.username forKey:@"username"];
    [coder encodeObject:self.displayName forKey:@"displayName"];
    [coder encodeObject:self.accountDescription forKey:@"accountDescription"];
    [coder encodeObject:self.avatarURLString forKey:@"avatarURLString"];
    [coder encodeObject:self.headerURLString forKey:@"headerURLString"];
    [coder encodeObject:self.note forKey:@"note"];
    [coder encodeInteger:self.statusesCount forKey:@"statusesCount"];
    [coder encodeInteger:self.followingCount forKey:@"followingCount"];
    [coder encodeInteger:self.followersCount forKey:@"followersCount"];
    [coder encodeBool:self.isLocked forKey:@"isLocked"];
    [coder encodeObject:self.url forKey:@"url"];
    [coder encodeObject:self.fields forKey:@"fields"];
    [coder encodeObject:self.featuredTags forKey:@"featuredTags"];
    [coder encodeObject:self.domain forKey:@"domain"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _accountID = [coder decodeObjectForKey:@"accountID"];
        _username = [coder decodeObjectForKey:@"username"];
        _displayName = [coder decodeObjectForKey:@"displayName"];
        _accountDescription = [coder decodeObjectForKey:@"accountDescription"];
        _avatarURLString = [coder decodeObjectForKey:@"avatarURLString"];
        _headerURLString = [coder decodeObjectForKey:@"headerURLString"];
        _note = [coder decodeObjectForKey:@"note"];
        _statusesCount = [coder decodeIntegerForKey:@"statusesCount"];
        _followingCount = [coder decodeIntegerForKey:@"followingCount"];
        _followersCount = [coder decodeIntegerForKey:@"followersCount"];
        _isLocked = [coder decodeBoolForKey:@"isLocked"];
        _url = [coder decodeObjectForKey:@"url"];
        _fields = [coder decodeObjectForKey:@"fields"];
        _featuredTags = [coder decodeObjectForKey:@"featuredTags"];
        _domain = [coder decodeObjectForKey:@"domain"];
    }
    return self;
}

@end
