//
//  FATExt_locationChange.m
//  FinAppletExt
//
//  Created by 王兆耀 on 2022/11/6.
//

#import "FATExt_locationChange.h"
#import "FATClient+ext.h"
#import "FATExt_LocationUpdateManager.h"

@implementation FATExt_locationChange

- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
//    if (self.enable) {
//        [FATExt_LocationUpdateManager sharedManager].context = self.context;
//        [[FATExt_LocationUpdateManager sharedManager] onLocationUpdate];
//    } else {
//        [FATExt_LocationUpdateManager sharedManager].context = self.context;
//        [[FATExt_LocationUpdateManager sharedManager] stopLocationUpdate];
//    }
    
    if (success) {
        success(@{});
    }
}

@end
