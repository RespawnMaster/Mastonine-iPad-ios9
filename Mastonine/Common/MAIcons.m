#import "MAIcons.h"
#import <CoreText/CoreText.h>

@implementation MAIcons

#pragma mark - Reply Icon (speech bubble)

+ (UIImage *)replyIconWithColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextSetLineWidth(ctx, 1.5);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    CGFloat w = size.width;
    CGFloat h = size.height;
    CGFloat pad = 3.0;

    CGMutablePathRef path = CGPathCreateMutable();

    CGFloat midY = h * 0.52;
    CGFloat topY = pad;
    CGFloat botY = h - pad - 4;
    CGFloat leftX = pad + 1;
    CGFloat rightX = w - pad - 1;
    CGFloat cpX = w * 0.2;

    CGPathMoveToPoint(path, NULL, leftX + 5, topY);
    CGPathAddLineToPoint(path, NULL, rightX - 3, topY);
    CGPathAddQuadCurveToPoint(path, NULL, rightX, topY, rightX, topY + 4);
    CGPathAddLineToPoint(path, NULL, rightX, midY - 2);
    CGPathAddQuadCurveToPoint(path, NULL, rightX, midY + 2, rightX - 3, midY + 2);
    CGPathAddLineToPoint(path, NULL, cpX + 10, midY + 2);
    CGPathAddLineToPoint(path, NULL, leftX + 4, botY);
    CGPathAddLineToPoint(path, NULL, cpX + 6, midY + 2);
    CGPathAddLineToPoint(path, NULL, leftX + 5, midY + 2);
    CGPathAddQuadCurveToPoint(path, NULL, leftX, midY + 2, leftX, midY - 2);
    CGPathAddLineToPoint(path, NULL, leftX, topY + 4);
    CGPathAddQuadCurveToPoint(path, NULL, leftX, topY, leftX + 5, topY);

    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);
    CGPathRelease(path);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

#pragma mark - Boost Icon (circular arrows)

+ (UIImage *)boostIconWithColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextSetLineWidth(ctx, 1.5);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    CGFloat cx = size.width / 2.0;
    CGFloat cy = size.height / 2.0;
    CGFloat r = MIN(size.width, size.height) / 2.0 - 3;

    // Arc (top portion of circle)
    CGContextAddArc(ctx, cx, cy + 1, r, M_PI * 1.2, M_PI * 2.15, 0);
    CGContextStrokePath(ctx);

    // Arrow head at end of arc (top right)
    CGFloat arrowX = cx + r * cos(M_PI * 2.15);
    CGFloat arrowY = cy + 1 + r * sin(M_PI * 2.15);
    CGContextMoveToPoint(ctx, arrowX - 2, arrowY + 3);
    CGContextAddLineToPoint(ctx, arrowX, arrowY - 1);
    CGContextAddLineToPoint(ctx, arrowX + 4, arrowY + 1);
    CGContextStrokePath(ctx);

    // Bottom arc
    CGContextAddArc(ctx, cx, cy - 1, r, M_PI * 0.2, M_PI * 1.15, 0);
    CGContextStrokePath(ctx);

    // Arrow head at end of bottom arc (bottom left)
    CGFloat arrowX2 = cx + r * cos(M_PI * 1.15);
    CGFloat arrowY2 = cy - 1 + r * sin(M_PI * 1.15);
    CGContextMoveToPoint(ctx, arrowX2 + 2, arrowY2 - 3);
    CGContextAddLineToPoint(ctx, arrowX2, arrowY2 + 1);
    CGContextAddLineToPoint(ctx, arrowX2 - 4, arrowY2 - 1);
    CGContextStrokePath(ctx);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

+ (UIImage *)boostActiveIconWithColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // Filled background circle
    CGFloat cx = size.width / 2.0;
    CGFloat cy = size.height / 2.0;
    CGFloat r = MIN(size.width, size.height) / 2.0 - 3;

    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(cx - r - 2, cy - r - 2, (r + 2) * 2, (r + 2) * 2));

    // White arcs on top
    CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(ctx, 1.5);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    CGContextAddArc(ctx, cx, cy + 1, r, M_PI * 1.2, M_PI * 2.15, 0);
    CGContextStrokePath(ctx);

    CGFloat arrowX = cx + r * cos(M_PI * 2.15);
    CGFloat arrowY = cy + 1 + r * sin(M_PI * 2.15);
    CGContextMoveToPoint(ctx, arrowX - 2, arrowY + 3);
    CGContextAddLineToPoint(ctx, arrowX, arrowY - 1);
    CGContextAddLineToPoint(ctx, arrowX + 4, arrowY + 1);
    CGContextStrokePath(ctx);

    CGContextAddArc(ctx, cx, cy - 1, r, M_PI * 0.2, M_PI * 1.15, 0);
    CGContextStrokePath(ctx);

    CGFloat arrowX2 = cx + r * cos(M_PI * 1.15);
    CGFloat arrowY2 = cy - 1 + r * sin(M_PI * 1.15);
    CGContextMoveToPoint(ctx, arrowX2 + 2, arrowY2 - 3);
    CGContextAddLineToPoint(ctx, arrowX2, arrowY2 + 1);
    CGContextAddLineToPoint(ctx, arrowX2 - 4, arrowY2 - 1);
    CGContextStrokePath(ctx);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

#pragma mark - Favourite Icon (star)

+ (UIImage *)favouriteIconWithColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextSetLineWidth(ctx, 1.5);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    CGFloat cx = size.width / 2.0;
    CGFloat cy = size.height / 2.0;
    CGFloat outerR = MIN(size.width, size.height) / 2.0 - 3;
    CGFloat innerR = outerR * 0.4;
    int points = 5;

    CGMutablePathRef path = CGPathCreateMutable();
    for (int i = 0; i < points * 2; i++) {
        CGFloat angle = -M_PI / 2.0 + (i * M_PI / points);
        CGFloat r = (i % 2 == 0) ? outerR : innerR;
        CGFloat x = cx + r * cos(angle);
        CGFloat y = cy + r * sin(angle);
        if (i == 0) {
            CGPathMoveToPoint(path, NULL, x, y);
        } else {
            CGPathAddLineToPoint(path, NULL, x, y);
        }
    }
    CGPathCloseSubpath(path);

    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);
    CGPathRelease(path);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

+ (UIImage *)favouriteActiveIconWithColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGFloat cx = size.width / 2.0;
    CGFloat cy = size.height / 2.0;
    CGFloat outerR = MIN(size.width, size.height) / 2.0 - 3;
    CGFloat innerR = outerR * 0.4;
    int points = 5;

    // Filled star
    CGMutablePathRef path = CGPathCreateMutable();
    for (int i = 0; i < points * 2; i++) {
        CGFloat angle = -M_PI / 2.0 + (i * M_PI / points);
        CGFloat r = (i % 2 == 0) ? outerR : innerR;
        CGFloat x = cx + r * cos(angle);
        CGFloat y = cy + r * sin(angle);
        if (i == 0) {
            CGPathMoveToPoint(path, NULL, x, y);
        } else {
            CGPathAddLineToPoint(path, NULL, x, y);
        }
    }
    CGPathCloseSubpath(path);

    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextAddPath(ctx, path);
    CGContextFillPath(ctx);

    // White border
    CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);
    CGPathRelease(path);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

#pragma mark - Share Icon (box with up arrow)

+ (UIImage *)shareIconWithColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextSetLineWidth(ctx, 1.5);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    CGFloat w = size.width;
    CGFloat h = size.height;
    CGFloat pad = 3.5;

    // Arrow pointing up
    CGFloat midX = w / 2.0;
    CGContextMoveToPoint(ctx, midX, pad + 2);
    CGContextAddLineToPoint(ctx, midX, h * 0.65);
    CGContextStrokePath(ctx);

    // Arrow head
    CGFloat arrowW = 5;
    CGContextMoveToPoint(ctx, midX - arrowW, h * 0.4);
    CGContextAddLineToPoint(ctx, midX, pad + 2);
    CGContextAddLineToPoint(ctx, midX + arrowW, h * 0.4);
    CGContextStrokePath(ctx);

    // Open box bottom
    CGFloat boxTop = h * 0.58;
    CGFloat boxBot = h - pad - 1;
    CGFloat boxLeft = pad + 2;
    CGFloat boxRight = w - pad - 2;

    // Box left side
    CGContextMoveToPoint(ctx, boxLeft, boxBot);
    CGContextAddLineToPoint(ctx, boxLeft, boxTop + 3);
    CGContextStrokePath(ctx);

    // Box bottom
    CGContextMoveToPoint(ctx, boxLeft, boxBot);
    CGContextAddLineToPoint(ctx, boxRight, boxBot);
    CGContextStrokePath(ctx);

    // Box right side
    CGContextMoveToPoint(ctx, boxRight, boxBot);
    CGContextAddLineToPoint(ctx, boxRight, boxTop + 3);
    CGContextStrokePath(ctx);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

#pragma mark - Tab Bar Icons

+ (UIImage *)homeIconWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor darkGrayColor] setStroke];
    CGContextSetLineWidth(ctx, 1.5);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    CGFloat w = size.width, h = size.height;
    CGFloat pad = 3;

    // Roof
    CGContextMoveToPoint(ctx, w / 2, pad);
    CGContextAddLineToPoint(ctx, w - pad, h * 0.42);
    CGContextStrokePath(ctx);

    // House body
    CGFloat bodyTop = h * 0.38;
    CGFloat bodyBot = h - pad;
    CGContextMoveToPoint(ctx, pad + 2, bodyTop);
    CGContextAddLineToPoint(ctx, pad + 2, bodyBot);
    CGContextAddLineToPoint(ctx, w - pad - 2, bodyBot);
    CGContextAddLineToPoint(ctx, w - pad - 2, bodyTop);
    CGContextStrokePath(ctx);

    // Door
    CGFloat doorW = w * 0.24;
    CGFloat doorH = h * 0.32;
    CGContextAddRect(ctx, CGRectMake((w - doorW) / 2, bodyBot - doorH, doorW, doorH));
    CGContextStrokePath(ctx);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

+ (UIImage *)bellIconWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor darkGrayColor] setStroke];
    CGContextSetLineWidth(ctx, 1.5);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    CGFloat w = size.width, h = size.height;
    CGFloat cx = w / 2;
    CGFloat pad = 3;

    // Bell body (arc)
    CGFloat bellTop = pad + 1;
    CGFloat bellBot = h * 0.72;
    CGFloat bellW = w * 0.35;
    CGContextAddArc(ctx, cx, bellTop + 2, bellW, M_PI, 0, 0);
    CGContextStrokePath(ctx);

    // Sides down
    CGContextMoveToPoint(ctx, cx - bellW, bellTop + 2);
    CGContextAddLineToPoint(ctx, cx - bellW * 0.6, bellBot);
    CGContextStrokePath(ctx);

    CGContextMoveToPoint(ctx, cx + bellW, bellTop + 2);
    CGContextAddLineToPoint(ctx, cx + bellW * 0.6, bellBot);
    CGContextStrokePath(ctx);

    // Bottom curve
    CGContextAddArc(ctx, cx, bellBot, bellW * 0.6, 0, M_PI, 0);
    CGContextStrokePath(ctx);

    // Clapper
    CGFloat clapperR = 2.5;
    CGContextAddArc(ctx, cx, bellBot + clapperR + 2, clapperR, 0, M_PI * 2, 0);
    CGContextStrokePath(ctx);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

+ (UIImage *)searchIconWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor darkGrayColor] setStroke];
    CGContextSetLineWidth(ctx, 1.8);
    CGContextSetLineCap(ctx, kCGLineCapRound);

    CGFloat w = size.width, h = size.height;
    CGFloat r = MIN(w, h) * 0.3;
    CGFloat cx = w * 0.44;
    CGFloat cy = h * 0.44;

    // Circle
    CGContextAddArc(ctx, cx, cy, r, 0, M_PI * 2, 0);
    CGContextStrokePath(ctx);

    // Handle
    CGFloat hx = cx + r * 0.72;
    CGFloat hy = cy + r * 0.72;
    CGContextMoveToPoint(ctx, hx, hy);
    CGContextAddLineToPoint(ctx, w - 3, h - 3);
    CGContextStrokePath(ctx);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

+ (UIImage *)personIconWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor darkGrayColor] setStroke];
    CGContextSetLineWidth(ctx, 1.5);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    CGFloat w = size.width, h = size.height;
    CGFloat cx = w / 2;

    // Head circle
    CGFloat headR = w * 0.2;
    CGFloat headY = h * 0.28;
    CGContextAddArc(ctx, cx, headY, headR, 0, M_PI * 2, 0);
    CGContextStrokePath(ctx);

    // Body arc
    CGFloat bodyY = h * 0.9;
    CGFloat bodyR = w * 0.45;
    CGContextAddArc(ctx, cx, bodyY, bodyR, M_PI * 1.15, M_PI * 1.85, 1);
    CGContextStrokePath(ctx);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

+ (UIImage *)gearIconWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor darkGrayColor] setStroke];
    CGContextSetLineWidth(ctx, 1.3);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    CGFloat w = size.width, h = size.height;
    CGFloat cx = w / 2, cy = h / 2;
    CGFloat outerR = MIN(w, h) * 0.38;
    CGFloat innerR = outerR * 0.55;
    int teeth = 8;

    // Gear teeth
    for (int i = 0; i < teeth; i++) {
        CGFloat angle = (i * M_PI * 2 / teeth);
        CGFloat cosA = cos(angle), sinA = sin(angle);
        CGFloat x1 = cx + innerR * cosA;
        CGFloat y1 = cy + innerR * sinA;
        CGFloat x2 = cx + outerR * cosA;
        CGFloat y2 = cy + outerR * sinA;
        CGFloat toothW = 2.5;
        CGFloat perpX = -sinA * toothW;
        CGFloat perpY = cosA * toothW;

        CGContextMoveToPoint(ctx, x1 + perpX, y1 + perpY);
        CGContextAddLineToPoint(ctx, x2 + perpX, y2 + perpY);
        CGContextAddLineToPoint(ctx, x2 - perpX, y2 - perpY);
        CGContextAddLineToPoint(ctx, x1 - perpX, y1 - perpY);
        CGContextClosePath(ctx);
        CGContextStrokePath(ctx);
    }

    // Center circle
    CGContextAddArc(ctx, cx, cy, innerR * 0.6, 0, M_PI * 2, 0);
    CGContextStrokePath(ctx);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

#pragma mark - Image with Count

+ (UIImage *)image:(UIImage *)image withCount:(NSInteger)count color:(UIColor *)color fontSize:(CGFloat)fontSize {
    NSString *countStr = count > 0 ? [NSString stringWithFormat:@"%ld", (long)count] : @"";
    UIFont *font = [UIFont systemFontOfSize:fontSize];

    CGSize countSize = [countStr sizeWithAttributes:@{NSFontAttributeName: font}];
    CGFloat spacing = countStr.length > 0 ? 4.0 : 0.0;
    CGFloat totalWidth = image.size.width + spacing + countSize.width;
    CGFloat totalHeight = MAX(image.size.height, countSize.height) + 4;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(totalWidth + 4, totalHeight), NO, 0);
    CGPoint imagePoint = CGPointMake(0, (totalHeight - image.size.height) / 2.0);
    [image drawAtPoint:imagePoint];

    if (countStr.length > 0) {
        NSDictionary *attrs = @{
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: color
        };
        CGPoint textPoint = CGPointMake(image.size.width + spacing, (totalHeight - countSize.height) / 2.0);
        [countStr drawAtPoint:textPoint withAttributes:attrs];
    }

    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [result imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

@end
