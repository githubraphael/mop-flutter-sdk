//
//  FATExt_startLocationUpdate.m
//  FinAppletExt
//
//  Created by 王兆耀 on 2022/11/3.
//

#import "FATExt_startLocationUpdate.h"
#import "FATClient+ext.h"
#import "FATExt_LocationUpdateManager.h"
#import "FATExt_locationAuthManager.h"

@implementation FATExt_startLocationUpdate

- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
        
    [[FATClient sharedClient] fat_requestAppletAuthorize:FATAuthorizationTypeLocation appletId:self.appletInfo.appId complete:^(NSInteger status) {
        if (status == 0) {
            [[FATExt_locationAuthManager shareInstance] fat_requestAppletLocationAuthorize:self.appletInfo isBackground:NO withComplete:^(BOOL status) {
                if (status) {
                    [FATExt_LocationUpdateManager sharedManager].context = self.context;
                    [[FATExt_LocationUpdateManager sharedManager] startLocationUpdateType:self.type isAllowsBackgroundLocationUpdates:NO withAppId:self.appletInfo.appId Success:success failure:failure cancel:cancel];
                } else {
                    if (failure) {
                        failure(@{@"errMsg" : @"system permission denied"});
                    }
                }
            }];
        } else if (status == 1) {
            //定位不能用
            if (failure) {
                failure(@{@"errMsg" : @"unauthorized,用户未授予位置权限"});
            }
        } else {
            if (failure) {
                failure(@{@"errMsg" : @"unauthorized disableauthorized,SDK被禁止申请位置权限"});
            }
        }
    }];
}

@end
