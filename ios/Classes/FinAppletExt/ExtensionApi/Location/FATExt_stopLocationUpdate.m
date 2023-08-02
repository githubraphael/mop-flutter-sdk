//
//  FATExt_stopLocationUpdate.m
//  FinAppletExt
//
//  Created by 王兆耀 on 2022/11/18.
//

#import "FATExt_stopLocationUpdate.h"
#import "FATClient+ext.h"
#import "FATExt_LocationUpdateManager.h"

@implementation FATExt_stopLocationUpdate

- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
    if (![self.appletInfo.appId isEqualToString:[FATExt_LocationUpdateManager sharedManager].appletId]) {
        if (success) {
            success(@{});
        }
        return;
    }
    [FATExt_LocationUpdateManager sharedManager].context = self.context;
    [[FATExt_LocationUpdateManager sharedManager] stopLocationUpdate];
    if (success) {
        success(@{});
    }
}

@end
