#import <UIKit/UIKit.h>

@interface MAComposeViewController : UIViewController

@property (nonatomic, copy) NSString *replyToStatusID;
@property (nonatomic, copy) NSString *replyToUsername;
@property (nonatomic, copy) NSString *draftText;
@property (nonatomic, copy) NSString *draftID;
@property (nonatomic, copy) NSString *visibility;
@property (nonatomic, copy) NSString *editStatusID;
@property (nonatomic, copy) NSString *editInitialText;
@property (nonatomic, copy) NSString *editInitialSpoilerText;

- (instancetype)initWithReplyToStatusID:(NSString *)statusID username:(NSString *)username;

@end
