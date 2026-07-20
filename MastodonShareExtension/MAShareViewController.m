#import "MAShareViewController.h"

@implementation MAShareViewController

- (BOOL)isContentValid {
    NSInteger maxLength = 500;
    return self.contentText.length > 0 && self.contentText.length <= maxLength;
}

- (NSInteger)charactersRemaining {
    return 500 - self.contentText.length;
}

- (void)didSelectPost {
    NSString *text = self.contentText ?: @"";
    NSURL *url = self.extensionContext.inputItems.count > 0 ?
        self.extensionContext.inputItems[0] : nil;

    NSString *shareText = text;
    if (url) {
        shareText = [NSString stringWithFormat:@"%@ %@", text, url.absoluteString];
    }

    NSDictionary *shareData = @{
        @"text": shareText,
        @"timestamp": @([[NSDate date] timeIntervalSince1970])
    };

    NSString *sharedDir = @"/var/mobile/Documents/Mastonine";
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:sharedDir]) {
        [fm createDirectoryAtPath:sharedDir withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *filename = [NSString stringWithFormat:@"share_%ld.txt", (long)[[NSDate date] timeIntervalSince1970]];
    NSString *filepath = [sharedDir stringByAppendingPathComponent:filename];

    NSData *data = [NSJSONSerialization dataWithJSONObject:shareData options:0 error:nil];
    [data writeToFile:filepath atomically:YES];

    NSURL *callbackURL = [NSURL URLWithString:[NSString stringWithFormat:@"mastonine://share?text=%@",
        [shareText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
    [self.extensionContext openURL:callbackURL completionHandler:nil];

    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (NSArray *)configurationItems {
    return @[];
}

@end
