#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MAMediaType) {
    MAMediaTypeImage,
    MAMediaTypeVideo,
    MAMediaTypeGIFV,
    MAMediaTypeAudio,
    MAMediaTypeUnknown
};

@interface MAMediaAttachment : NSObject

@property (nonatomic, copy) NSString *attachmentID;
@property (nonatomic, assign) MAMediaType type;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *previewURL;
@property (nonatomic, copy) NSString *remoteURL;
@property (nonatomic, copy) NSString *textURL;
@property (nonatomic, copy) NSString *descriptionText;
@property (nonatomic, copy) NSString *blurhash;

+ (instancetype)attachmentFromDictionary:(NSDictionary *)dict;

@end
