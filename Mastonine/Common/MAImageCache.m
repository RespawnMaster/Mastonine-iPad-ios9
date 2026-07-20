#import "MAImageCache.h"
#import <CommonCrypto/CommonDigest.h>

@interface MAImageCache ()

@property (nonatomic, strong) NSCache *memoryCache;
@property (nonatomic, strong) NSMutableDictionary *pendingCallbacks;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@property (nonatomic, strong) dispatch_queue_t diskQueue;
@property (nonatomic, strong) NSString *diskCachePath;

@end

@implementation MAImageCache

+ (instancetype)sharedCache {
    static MAImageCache *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[MAImageCache alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _memoryCache = [[NSCache alloc] init];
        _memoryCache.totalCostLimit = 20 * 1024 * 1024;
        _pendingCallbacks = [NSMutableDictionary dictionary];
        _callbackQueue = dispatch_queue_create("com.mastonine.imagecache.callback", DISPATCH_QUEUE_SERIAL);
        _diskQueue = dispatch_queue_create("com.mastonine.imagecache.disk", DISPATCH_QUEUE_SERIAL);

        NSString *caches = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        _diskCachePath = [caches stringByAppendingPathComponent:@"MAImageCache"];
        [[NSFileManager defaultManager] createDirectoryAtPath:_diskCachePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    return self;
}

- (NSString *)diskPathForURL:(NSURL *)url {
    if (!url) return nil;
    NSString *key = url.absoluteString;
    unsigned char md5[CC_MD5_DIGEST_LENGTH];
    CC_MD5(key.UTF8String, (CC_LONG)key.length, md5);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hex appendFormat:@"%02x", md5[i]];
    }
    return [_diskCachePath stringByAppendingPathComponent:hex];
}

- (UIImage *)diskImageForURL:(NSURL *)url {
    NSString *path = [self diskPathForURL:url];
    if (!path) return nil;
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) return nil;
    return [UIImage imageWithData:data];
}

- (UIImage *)diskImageForURL:(NSURL *)url size:(CGSize)size {
    NSString *path = [self diskPathForURL:url];
    if (!path) return nil;
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) return nil;
    return [self downsampleImageData:data toSize:size];
}

- (void)storeImage:(UIImage *)image data:(NSData *)data forURL:(NSURL *)url {
    if (!image || !data || !url) return;
    [self.memoryCache setObject:image forKey:url.absoluteString cost:data.length];
    NSString *path = [self diskPathForURL:url];
    if (path) {
        dispatch_async(_diskQueue, ^{
            [data writeToFile:path atomically:YES];
        });
    }
}

- (UIImage *)downsampleImageData:(NSData *)data toSize:(CGSize)size {
    if (size.width <= 0 || size.height <= 0) {
        return [UIImage imageWithData:data];
    }

    UIImage *source = [UIImage imageWithData:data];
    if (!source) return nil;

    CGFloat sourceWidth = source.size.width;
    CGFloat sourceHeight = source.size.height;

    CGFloat scaleX = size.width / sourceWidth;
    CGFloat scaleY = size.height / sourceHeight;
    CGFloat scale = MIN(scaleX, scaleY);
    if (scale > 1.0) scale = 1.0;

    CGFloat destWidth = sourceWidth * scale;
    CGFloat destHeight = sourceHeight * scale;
    if (destWidth < 1) destWidth = 1;
    if (destHeight < 1) destHeight = 1;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(destWidth, destHeight), NO, 0);
    [source drawInRect:CGRectMake(0, 0, destWidth, destHeight)];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return result;
}

#pragma mark - Fetch (thumbnail size)

- (void)fetchImageAtURL:(NSURL *)url size:(CGSize)size completion:(void (^)(UIImage *))completion {
    if (!url) {
        if (completion) completion(nil);
        return;
    }

    NSString *cacheKey = size.width > 0 ? [NSString stringWithFormat:@"%@_%.0fx%.0f", url.absoluteString, size.width, size.height] : url.absoluteString;

    UIImage *memCached = [self.memoryCache objectForKey:cacheKey];
    if (memCached) {
        if (completion) completion(memCached);
        return;
    }

    // Check disk on background queue
    dispatch_async(_diskQueue, ^{
        UIImage *diskCached = [self diskImageForURL:url];
        if (diskCached) {
            UIImage *downsampled = [self downsampleImageData:[NSData dataWithContentsOfFile:[self diskPathForURL:url]] toSize:size];
            if (downsampled) {
                [self.memoryCache setObject:downsampled forKey:cacheKey cost:0];
                dispatch_async(self.callbackQueue, ^{
                    if (completion) completion(downsampled);
                });
                return;
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self _fetchFromNetwork:url size:size cacheKey:cacheKey completion:completion];
        });
    });
}

- (void)_fetchFromNetwork:(NSURL *)url size:(CGSize)size cacheKey:(NSString *)cacheKey completion:(void (^)(UIImage *))completion {
    @synchronized(self.pendingCallbacks) {
        NSMutableArray *callbacks = self.pendingCallbacks[cacheKey];
        if (callbacks) {
            if (completion) [callbacks addObject:[completion copy]];
            return;
        }
        callbacks = [NSMutableArray array];
        if (completion) [callbacks addObject:[completion copy]];
        self.pendingCallbacks[cacheKey] = callbacks;
    }

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) {
            [self fireCallbacksForCacheKey:cacheKey withImage:nil];
            return;
        }

        UIImage *fullImage = [UIImage imageWithData:data];
        if (!fullImage) {
            [self fireCallbacksForCacheKey:cacheKey withImage:nil];
            return;
        }

        UIImage *displayImage;
        if (size.width > 0 && size.height > 0) {
            displayImage = [self downsampleImageData:data toSize:size];
        } else {
            displayImage = fullImage;
        }

        [self storeImage:displayImage data:data forURL:url];

        dispatch_async(self.callbackQueue, ^{
            [self fireCallbacksForCacheKey:cacheKey withImage:displayImage];
        });
    }];
    [task resume];
}

#pragma mark - Fetch (original size)

- (void)fetchImageAtURL:(NSURL *)url completion:(void (^)(UIImage *))completion {
    [self fetchImageAtURL:url size:CGSizeZero completion:completion];
}

- (UIImage *)cachedImageForURL:(NSURL *)url {
    return [self.memoryCache objectForKey:url.absoluteString];
}

- (UIImage *)cachedImageForURL:(NSURL *)url size:(CGSize)size {
    if (size.width <= 0 || size.height <= 0) {
        return [self cachedImageForURL:url];
    }
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%.0fx%.0f", url.absoluteString, size.width, size.height];
    return [self.memoryCache objectForKey:cacheKey];
}

- (void)fireCallbacksForCacheKey:(NSString *)cacheKey withImage:(UIImage *)image {
    NSArray *callbacks;
    @synchronized(self.pendingCallbacks) {
        callbacks = [self.pendingCallbacks[cacheKey] copy];
        [self.pendingCallbacks removeObjectForKey:cacheKey];
    }
    dispatch_async(self.callbackQueue, ^{
        for (void (^callback)(UIImage *) in callbacks) {
            callback(image);
        }
    });
}

- (void)clearCache {
    [self.memoryCache removeAllObjects];
    dispatch_async(_diskQueue, ^{
        [[NSFileManager defaultManager] removeItemAtPath:self.diskCachePath error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:self.diskCachePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    });
}

- (NSUInteger)memoryUsage {
    return self.memoryCache.totalCostLimit;
}

@end
