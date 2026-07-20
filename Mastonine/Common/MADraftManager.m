#import "MADraftManager.h"

@interface MADraftManager ()

@property (nonatomic, strong) NSString *draftsDirectory;

@end

@implementation MADraftManager

+ (instancetype)sharedManager {
    static MADraftManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[MADraftManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _draftsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        _draftsDirectory = [_draftsDirectory stringByAppendingPathComponent:@"Mastonine/Drafts"];
        [self ensureDraftsDirectoryExists];
    }
    return self;
}

- (void)ensureDraftsDirectoryExists {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.draftsDirectory]) {
        [fileManager createDirectoryAtPath:self.draftsDirectory
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
}

- (void)saveDraftWithText:(NSString *)text inReplyToStatusID:(NSString *)replyToStatusID replyToUsername:(NSString *)replyToUsername visibility:(NSString *)visibility {
    NSString *draftID = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];

    NSDictionary *draft = @{
        @"text": text ?: @"",
        @"replyToStatusID": replyToStatusID ?: @"",
        @"replyToUsername": replyToUsername ?: @"",
        @"visibility": visibility ?: @"public",
        @"timestamp": @([[NSDate date] timeIntervalSince1970]),
        @"draftID": draftID
    };

    NSString *filePath = [self.draftsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", draftID]];

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:draft
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:&error];
    if (error) {
        return;
    }

    [jsonData writeToFile:filePath atomically:YES];
}

- (NSArray *)loadAllDrafts {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.draftsDirectory error:&error];

    if (error) {
        return @[];
    }

    NSMutableArray *drafts = [NSMutableArray array];

    for (NSString *filename in contents) {
        if (![filename hasSuffix:@".json"]) continue;

        NSString *filePath = [self.draftsDirectory stringByAppendingPathComponent:filename];
        NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
        if (!jsonData) continue;

        NSError *jsonError = nil;
        NSDictionary *draft = [NSJSONSerialization JSONObjectWithData:jsonData
                                                             options:0
                                                               error:&jsonError];
        if (jsonError || ![draft isKindOfClass:[NSDictionary class]]) continue;

        [drafts addObject:draft];
    }

    NSArray *sortedDrafts = [drafts sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        NSTimeInterval timeA = [a[@"timestamp"] doubleValue];
        NSTimeInterval timeB = [b[@"timestamp"] doubleValue];
        return [@(timeB) compare:@(timeA)];
    }];

    return sortedDrafts;
}

- (void)deleteDraftWithID:(NSString *)draftID {
    NSString *filePath = [self.draftsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", draftID]];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
}

- (void)deleteAllDrafts {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.draftsDirectory error:&error];

    if (error) {
        return;
    }

    for (NSString *filename in contents) {
        if (![filename hasSuffix:@".json"]) continue;

        NSString *filePath = [self.draftsDirectory stringByAppendingPathComponent:filename];
        [fileManager removeItemAtPath:filePath error:nil];
    }
}

@end
