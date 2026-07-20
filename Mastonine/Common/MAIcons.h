#import <UIKit/UIKit.h>

@interface MAIcons : NSObject

+ (UIImage *)replyIconWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)boostIconWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)boostActiveIconWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)favouriteIconWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)favouriteActiveIconWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)shareIconWithColor:(UIColor *)color size:(CGSize)size;

+ (UIImage *)homeIconWithSize:(CGSize)size;
+ (UIImage *)bellIconWithSize:(CGSize)size;
+ (UIImage *)searchIconWithSize:(CGSize)size;
+ (UIImage *)personIconWithSize:(CGSize)size;
+ (UIImage *)gearIconWithSize:(CGSize)size;

+ (UIImage *)image:(UIImage *)image withCount:(NSInteger)count color:(UIColor *)color fontSize:(CGFloat)fontSize;

@end
