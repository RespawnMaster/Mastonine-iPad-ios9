#import <UIKit/UIKit.h>

@interface MAImageCache : NSObject

+ (instancetype)sharedCache;
- (void)fetchImageAtURL:(NSURL *)url completion:(void (^)(UIImage *))completion;
- (void)fetchImageAtURL:(NSURL *)url size:(CGSize)size completion:(void (^)(UIImage *))completion;
- (UIImage *)cachedImageForURL:(NSURL *)url;
- (UIImage *)cachedImageForURL:(NSURL *)url size:(CGSize)size;
- (void)clearCache;
- (NSUInteger)memoryUsage;

@end
