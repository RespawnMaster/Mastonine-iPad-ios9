#import <Foundation/Foundation.h>

@interface MADraftManager : NSObject

+ (instancetype)sharedManager;
- (void)saveDraftWithText:(NSString *)text inReplyToStatusID:(NSString *)replyToStatusID replyToUsername:(NSString *)replyToUsername visibility:(NSString *)visibility;
- (NSArray *)loadAllDrafts;
- (void)deleteDraftWithID:(NSString *)draftID;
- (void)deleteAllDrafts;

@end
