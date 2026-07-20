#import "MATheme.h"

static NSString * const kDarkModeKey = @"dark_mode_enabled";

@implementation MATheme

+ (BOOL)isDarkMode {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDarkModeKey];
}

+ (void)setDarkMode:(BOOL)dark {
    [[NSUserDefaults standardUserDefaults] setBool:dark forKey:kDarkModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self applyAppearance];
}

+ (void)applyAppearance {
    BOOL dark = [self isDarkMode];

    [[UINavigationBar appearance] setBarTintColor:dark ? [UIColor colorWithRed:0.11 green:0.11 blue:0.14 alpha:1.0] : [UIColor whiteColor]];
    [[UINavigationBar appearance] setTintColor:dark ? [UIColor whiteColor] : [self primaryColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: dark ? [UIColor whiteColor] : [UIColor blackColor]}];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setBarStyle:dark ? UIBarStyleBlack : UIBarStyleDefault];

    [[UITabBar appearance] setBarTintColor:dark ? [UIColor colorWithRed:0.11 green:0.11 blue:0.14 alpha:1.0] : [UIColor whiteColor]];
    [[UITabBar appearance] setTintColor:dark ? [self primaryColor] : [self primaryColor]];
    [[UITabBar appearance] setTranslucent:NO];
    [[UITabBar appearance] setBarStyle:dark ? UIBarStyleBlack : UIBarStyleDefault];

    [[UITableView appearance] setBackgroundColor:[self backgroundColor]];
    [[UITableView appearance] setSeparatorColor:[self separatorColor]];

    [[UIApplication sharedApplication] setStatusBarStyle:dark ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault animated:NO];
}

#pragma mark - Colors

+ (UIColor *)primaryColor {
    return [UIColor colorWithRed:88.0/255.0 green:55.0/255.0 blue:181.0/255.0 alpha:1.0];
}

+ (UIColor *)primaryDarkColor {
    return [UIColor colorWithRed:68.0/255.0 green:40.0/255.0 blue:142.0/255.0 alpha:1.0];
}

+ (UIColor *)accentColor {
    return [UIColor colorWithRed:88.0/255.0 green:55.0/255.0 blue:181.0/255.0 alpha:1.0];
}

+ (UIColor *)backgroundColor {
    if ([self isDarkMode]) {
        return [UIColor colorWithRed:0.11 green:0.11 blue:0.13 alpha:1.0];
    }
    return [UIColor colorWithRed:0.96 green:0.96 blue:0.97 alpha:1.0];
}

+ (UIColor *)cardColor {
    if ([self isDarkMode]) {
        return [UIColor colorWithRed:0.17 green:0.17 blue:0.20 alpha:1.0];
    }
    return [UIColor whiteColor];
}

+ (UIColor *)textColor {
    if ([self isDarkMode]) {
        return [UIColor colorWithRed:0.70 green:0.70 blue:0.73 alpha:1.0];
    }
    return [UIColor colorWithRed:0.11 green:0.11 blue:0.14 alpha:1.0];
}

+ (UIColor *)secondaryTextColor {
    if ([self isDarkMode]) {
        return [UIColor colorWithRed:0.48 green:0.48 blue:0.53 alpha:1.0];
    }
    return [UIColor colorWithRed:0.45 green:0.45 blue:0.50 alpha:1.0];
}

+ (UIColor *)separatorColor {
    if ([self isDarkMode]) {
        return [UIColor colorWithRed:0.28 green:0.28 blue:0.32 alpha:1.0];
    }
    return [UIColor colorWithRed:0.85 green:0.85 blue:0.87 alpha:1.0];
}

+ (UIColor *)boostColor {
    return [UIColor colorWithRed:0.13 green:0.55 blue:0.13 alpha:1.0];
}

+ (UIColor *)favoriteColor {
    return [UIColor colorWithRed:0.94 green:0.57 blue:0.0 alpha:1.0];
}

+ (UIColor *)navigationBarColor {
    if ([self isDarkMode]) {
        return [UIColor colorWithRed:0.11 green:0.11 blue:0.14 alpha:1.0];
    }
    return [UIColor whiteColor];
}

+ (UIColor *)tabBarColor {
    if ([self isDarkMode]) {
        return [UIColor colorWithRed:0.11 green:0.11 blue:0.14 alpha:1.0];
    }
    return [UIColor whiteColor];
}

+ (UIColor *)linkColor {
    if ([self isDarkMode]) {
        return [UIColor colorWithRed:140.0/255.0 green:180.0/255.0 blue:235.0/255.0 alpha:1.0];
    }
    return [UIColor colorWithRed:88.0/255.0 green:55.0/255.0 blue:181.0/255.0 alpha:1.0];
}

+ (UIColor *)dangerColor {
    return [UIColor colorWithRed:0.86 green:0.23 blue:0.18 alpha:1.0];
}

+ (UIColor *)toolbarBackgroundColor {
    if ([self isDarkMode]) {
        return [UIColor colorWithRed:0.14 green:0.14 blue:0.17 alpha:1.0];
    }
    return [UIColor colorWithRed:0.95 green:0.95 blue:0.96 alpha:1.0];
}

#pragma mark - Fonts

+ (UIFont *)boldFontWithSize:(CGFloat)size {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_8_1) {
        return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
    }
    return [UIFont boldSystemFontOfSize:size];
}

+ (UIFont *)fontWithSize:(CGFloat)size {
    return [UIFont systemFontOfSize:size];
}

+ (UIFont *)lightFontWithSize:(CGFloat)size {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_8_1) {
        return [UIFont systemFontOfSize:size weight:UIFontWeightLight];
    }
    return [UIFont systemFontOfSize:size];
}

+ (UIFont *)monoFontWithSize:(CGFloat)size {
    UIFont *font = [UIFont fontWithName:@"Menlo" size:size];
    if (!font) {
        font = [UIFont fontWithName:@"Courier" size:size];
    }
    if (!font) {
        font = [UIFont monospacedDigitSystemFontOfSize:size weight:UIFontWeightRegular];
    }
    return font;
}

@end
