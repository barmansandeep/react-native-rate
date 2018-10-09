#import "RNRate.h"

@implementation RNRate
RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(rate: (NSDictionary *)options : (RCTResponseSenderBlock) callback) {
    NSString *AppleAppID = [RCTConvert NSString:options[@"AppleAppID"]];
    NSString *AppleNativePrefix = [RCTConvert NSString:options[@"AppleNativePrefix"]];
    BOOL preferInApp = [RCTConvert BOOL:options[@"preferInApp"]];
    float inAppDelay = [RCTConvert float:options[@"inAppDelay"]];
    BOOL openAppStoreIfInAppFails = [RCTConvert BOOL:options[@"openAppStoreIfInAppFails"]];


    NSString *suffix = @"?action=write-review";

    NSString *url = [NSString stringWithFormat:@"%@%@%@", AppleNativePrefix, AppleAppID, suffix];
    double delayInSeconds = 5.0;

    if (preferInApp) {
        if ([SKStoreReviewController class]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUInteger windowCount = [[[UIApplication sharedApplication] windows] count];
                
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    
                    [SKStoreReviewController requestReview];
                });


                float checkTime = 0.1;
                int iterations = (int)(inAppDelay / checkTime);

                [self possiblyOpenAppStore:url :windowCount :callback :checkTime :iterations :openAppStoreIfInAppFails];
            });
        } else {
            [self openAppStoreAndRate:url];
            callback(@[[NSNumber numberWithBool:true]]);
        }
    } else {
        //[self openAppStoreAndRate:url];
        //callback(@[[NSNumber numberWithBool:true]]);
    }
}

- (void) possiblyOpenAppStore : (NSString *) url : (NSUInteger) originalWindowCount : (RCTResponseSenderBlock) callback : (float) checkTime : (int) iterations : (BOOL) openAppStoreIfInAppFails {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(checkTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSUInteger newWindowCount = [[[UIApplication sharedApplication] windows] count];

        if (newWindowCount > originalWindowCount) {
            callback(@[[NSNumber numberWithBool:true]]);
        } else if (newWindowCount < originalWindowCount) {
            callback(@[[NSNumber numberWithBool:false]]);
        } else {
            int newInterations = iterations - 1;
            if (newInterations > 0) {
                [self possiblyOpenAppStore:url :originalWindowCount :callback :checkTime :newInterations :openAppStoreIfInAppFails];
            } else {
                if (openAppStoreIfInAppFails) {
                  [self openAppStoreAndRate:url];
                }
                callback(@[[NSNumber numberWithBool:false]]);
            }
        }
    });
}

- (void) openAppStoreAndRate : (NSString *) url {
    double delayInSeconds = 5.0;

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString:url]];
    });

}



@end
