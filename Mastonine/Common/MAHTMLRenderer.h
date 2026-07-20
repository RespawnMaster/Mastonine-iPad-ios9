#import <UIKit/UIKit.h>

@interface MAHTMLRenderer : NSObject

+ (NSAttributedString *)renderHTML:(NSString *)html withFontSize:(CGFloat)fontSize color:(UIColor *)color;
+ (NSAttributedString *)renderHTML:(NSString *)html;
+ (NSAttributedString *)renderPlainText:(NSString *)text withFontSize:(CGFloat)fontSize color:(UIColor *)color;
+ (CGSize)sizeForHTML:(NSString *)html withWidth:(CGFloat)width fontSize:(CGFloat)fontSize;
+ (void)clearCache;

@end
