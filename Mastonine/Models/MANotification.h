#import <Foundation/Foundation.h>

@class MAStatus;
@class MAAccount;

typedef NS_ENUM(NSInteger, MANotificationType) {
    MANotificationTypeMention,
    MANotificationTypeReblog,
    MANotificationTypeFavourite,
    MANotificationTypeFollow,
    MANotificationTypeFollowRequest,
    MANotificationTypeUnknown
};

@interface MANotification : NSObject

@property (nonatomic, copy) NSString *notificationID;
@property (nonatomic, assign) MANotificationType type;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) MAStatus *status;
@property (nonatomic, strong) MAAccount *account;

+ (instancetype)notificationFromDictionary:(NSDictionary *)dict;
- (NSString *)relativeTimeString;

@end
