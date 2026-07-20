#import <Foundation/Foundation.h>

@interface MAList : NSObject
@property (nonatomic, copy) NSString *listID;
@property (nonatomic, copy) NSString *title;
+ (instancetype)listFromDictionary:(NSDictionary *)dict;
@end
