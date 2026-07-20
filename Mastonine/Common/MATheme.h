#import <UIKit/UIKit.h>

@interface MATheme : NSObject

+ (BOOL)isDarkMode;
+ (void)setDarkMode:(BOOL)dark;

+ (UIColor *)primaryColor;
+ (UIColor *)primaryDarkColor;
+ (UIColor *)accentColor;
+ (UIColor *)backgroundColor;
+ (UIColor *)cardColor;
+ (UIColor *)textColor;
+ (UIColor *)secondaryTextColor;
+ (UIColor *)separatorColor;
+ (UIColor *)boostColor;
+ (UIColor *)favoriteColor;
+ (UIColor *)navigationBarColor;
+ (UIColor *)tabBarColor;
+ (UIColor *)linkColor;
+ (UIColor *)dangerColor;
+ (UIColor *)toolbarBackgroundColor;
+ (UIFont *)boldFontWithSize:(CGFloat)size;
+ (UIFont *)fontWithSize:(CGFloat)size;
+ (UIFont *)lightFontWithSize:(CGFloat)size;
+ (UIFont *)monoFontWithSize:(CGFloat)size;

+ (void)applyAppearance;

@end
