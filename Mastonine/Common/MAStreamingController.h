#import <Foundation/Foundation.h>

extern NSString *const MAStreamingDidReceiveStatus;
extern NSString *const MAStreamingDidReceiveNotification;
extern NSString *const MAStreamingDidDeleteStatus;
extern NSString *const MAStreamingDidUpdateStatus;

@interface MAStreamingController : NSObject

@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) BOOL isUserStream;
@property (nonatomic, copy) NSString *currentTimelineType;

- (void)setBaseURL:(NSString *)baseURL accessToken:(NSString *)accessToken;
- (void)connectToTimeline:(NSString *)timelineType;
- (void)connectToUserStream;
- (void)disconnect;

@end
