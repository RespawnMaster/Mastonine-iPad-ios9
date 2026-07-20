#import <Foundation/Foundation.h>

@interface MAFilterManager : NSObject

+ (instancetype)sharedManager;
- (void)loadFiltersWithCompletion:(void (^)(void))completion;
- (BOOL)shouldFilterStatusWithContent:(NSString *)content spoilerText:(NSString *)spoilerText;
- (NSArray *)activeFilters;
- (void)addFilterWithPhrase:(NSString *)phrase context:(NSArray *)contexts expiresInSeconds:(NSInteger)expires completion:(void (^)(NSError *error))completion;
- (void)deleteFilterWithID:(NSString *)filterID completion:(void (^)(NSError *error))completion;

@end
