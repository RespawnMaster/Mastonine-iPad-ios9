#import "MAHTMLRenderer.h"
#import "MATheme.h"
#import <CoreText/CoreText.h>

static NSCache *_renderCache = nil;

@implementation MAHTMLRenderer

+ (void)initialize {
    if (self == [MAHTMLRenderer class]) {
        _renderCache = [[NSCache alloc] init];
        _renderCache.countLimit = 100;
    }
}

+ (NSAttributedString *)renderHTML:(NSString *)html {
    return [self renderHTML:html withFontSize:15.0 color:[MATheme textColor]];
}

+ (NSAttributedString *)renderHTML:(NSString *)html withFontSize:(CGFloat)fontSize color:(UIColor *)color {
    if (!html || html.length == 0) {
        return [[NSAttributedString alloc] init];
    }

    NSString *cacheKey = [NSString stringWithFormat:@"%lu:%@", (unsigned long)(fontSize * 100), html];
    NSAttributedString *cached = [_renderCache objectForKey:cacheKey];
    if (cached) return cached;

    NSString *processed = html;
    processed = [self replaceEmojisInHTML:processed];

    NSDictionary *documentAttributes = @{
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
        NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
    };

    NSData *htmlData = [processed dataUsingEncoding:NSUTF8StringEncoding];
    if (!htmlData) return [[NSAttributedString alloc] initWithString:processed];

    NSError *error = nil;
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithData:htmlData
                                                                                    options:documentAttributes
                                                                         documentAttributes:nil
                                                                                      error:&error];
    if (error || !attrString) {
        return [[NSAttributedString alloc] initWithString:processed attributes:@{
            NSFontAttributeName: [MATheme fontWithSize:fontSize],
            NSForegroundColorAttributeName: color
        }];
    }

    NSUInteger len = attrString.length;
    for (NSUInteger i = 0; i < len; i++) {
        [attrString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(i, 1)];
    }

    NSMutableArray *linkRanges = [NSMutableArray array];

    [attrString enumerateAttribute:NSLinkAttributeName
                           inRange:NSMakeRange(0, attrString.length)
                           options:0
                        usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            NSString *urlStr = nil;
            if ([value isKindOfClass:[NSURL class]]) {
                urlStr = [(NSURL *)value absoluteString];
            } else if ([value isKindOfClass:[NSString class]]) {
                urlStr = value;
            }
            if (urlStr) {
                [linkRanges addObject:@[[NSValue valueWithRange:range], urlStr]];
            }
        }
    }];

    if (linkRanges.count == 0) {
        linkRanges = [self parseLinkRangesFromHTML:processed inText:[attrString string]];
    }

    UIColor *linkCol = [MATheme linkColor];
    for (NSArray *pair in linkRanges) {
        NSValue *rv = pair[0];
        NSString *urlStr = pair[1];
        NSRange range = [rv rangeValue];
        if (range.location == NSNotFound || range.location + range.length > attrString.length) continue;

        [attrString addAttribute:NSForegroundColorAttributeName value:linkCol range:range];
        [attrString addAttribute:@"MALinkURL" value:urlStr range:range];
    }

    [attrString enumerateAttribute:NSLinkAttributeName
                           inRange:NSMakeRange(0, attrString.length)
                           options:0
                        usingBlock:^(id value, NSRange range, BOOL *stop) {
        [attrString removeAttribute:NSLinkAttributeName range:range];
    }];

    [attrString enumerateAttribute:NSFontAttributeName
                           inRange:NSMakeRange(0, attrString.length)
                           options:0
                        usingBlock:^(id value, NSRange range, BOOL *stop) {
        UIFont *newFont = [MATheme fontWithSize:fontSize];
        [attrString addAttribute:NSFontAttributeName value:newFont range:range];
    }];

    NSAttributedString *result = [attrString copy];
    [_renderCache setObject:result forKey:cacheKey];
    return result;
}

+ (NSAttributedString *)renderPlainText:(NSString *)text withFontSize:(CGFloat)fontSize color:(UIColor *)color {
    if (!text) return [[NSAttributedString alloc] init];
    return [[NSAttributedString alloc] initWithString:text attributes:@{
        NSFontAttributeName: [MATheme fontWithSize:fontSize],
        NSForegroundColorAttributeName: color
    }];
}

+ (CGSize)sizeForHTML:(NSString *)html withWidth:(CGFloat)width fontSize:(CGFloat)fontSize {
    NSAttributedString *attrString = [self renderHTML:html withFontSize:fontSize color:[MATheme textColor]];
    if (attrString.length == 0) return CGSizeZero;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
    CFRange fitRange;
    CGSize constraintSize = CGSizeMake(width, CGFLOAT_MAX);
    CGSize coreSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, attrString.length), NULL, constraintSize, &fitRange);
    CFRelease(framesetter);
    return CGSizeMake(ceil(coreSize.width), ceil(coreSize.height));
}

+ (void)clearCache {
    [_renderCache removeAllObjects];
}

#pragma mark - Link Parsing

+ (NSMutableArray *)parseLinkRangesFromHTML:(NSString *)html inText:(NSString *)plainText {
    NSMutableArray *result = [NSMutableArray array];
    NSString *lower = [html lowercaseString];
    NSUInteger pos = 0;

    while (pos < lower.length) {
        NSRange aOpen = [lower rangeOfString:@"<a " options:0 range:NSMakeRange(pos, lower.length - pos)];
        if (aOpen.location == NSNotFound) break;

        NSRange hrefRange = [lower rangeOfString:@"href=\"" options:0 range:NSMakeRange(aOpen.location, aOpen.length + 200)];
        if (hrefRange.location == NSNotFound) { pos = aOpen.location + 1; continue; }

        NSUInteger hrefStart = hrefRange.location + hrefRange.length;
        NSUInteger hrefEnd = [lower rangeOfString:@"\"" options:0 range:NSMakeRange(hrefStart, lower.length - hrefStart)].location;
        if (hrefEnd == NSNotFound || hrefEnd - hrefStart > 500) { pos = hrefStart; continue; }

        NSString *href = [html substringWithRange:NSMakeRange(hrefStart, hrefEnd - hrefStart)];

        NSRange closeTag = [lower rangeOfString:@">" options:0 range:NSMakeRange(hrefEnd, lower.length - hrefEnd)];
        if (closeTag.location == NSNotFound) { pos = hrefEnd; continue; }

        NSRange endA = [lower rangeOfString:@"</a>" options:0 range:NSMakeRange(closeTag.location, lower.length - closeTag.location)];
        if (endA.location == NSNotFound) { pos = closeTag.location + 1; continue; }

        NSString *linkText = [html substringWithRange:NSMakeRange(closeTag.location + 1, endA.location - closeTag.location - 1)];
        NSString *cleanText = [self stripHTMLTags:linkText];

        if (cleanText.length > 0 && plainText.length > 0) {
            NSRange found = [plainText rangeOfString:cleanText options:NSBackwardsSearch];
            if (found.location != NSNotFound) {
                [result addObject:@[[NSValue valueWithRange:found], href]];
            }
        }

        pos = endA.location + 4;
    }

    return result;
}

+ (NSString *)stripHTMLTags:(NSString *)html {
    NSMutableString *result = [NSMutableString string];
    BOOL inTag = NO;
    for (NSUInteger i = 0; i < html.length; i++) {
        unichar c = [html characterAtIndex:i];
        if (c == '<') { inTag = YES; continue; }
        if (c == '>') { inTag = NO; continue; }
        if (!inTag) {
            [result appendFormat:@"%C", c];
        }
    }
    return [result copy];
}

#pragma mark - Emoji Replacement

+ (NSString *)replaceEmojisInHTML:(NSString *)html {
    NSArray *emojiMap = @[
        @[@"\xE2\x80\x8B", @""],
    ];
    NSMutableString *result = [html mutableCopy];
    for (NSArray *pair in emojiMap) {
        [result replaceOccurrencesOfString:pair[0] withString:pair[1] options:0 range:NSMakeRange(0, result.length)];
    }
    return [result copy];
}

@end
