//
//  FATExt_startLocationUpdateBackground.m
//  FinAppletExt
//
//  Created by 王兆耀 on 2022/11/3.
//

#import "FATExt_startLocationUpdateBackground.h"
#import "FATClient+ext.h"
#import "FATExt_LocationUpdateManager.h"
#import "FATExt_locationAuthManager.h"

@implementation FATExt_startLocationUpdateBackground

- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
    if ([FATExt_LocationUpdateManager sharedManager].locationIsInit && [FATExt_LocationUpdateManager sharedManager].locationManager.allowsBackgroundLocationUpdates && ![self.appletInfo.appId isEqualToString:[FATExt_LocationUpdateManager sharedManager].appletId]) {
        if (failure) {
            failure(@{@"errMsg" : @"reach max concurrent background count"});
        }
        return;
    }
    [[FATClient sharedClient] fat_requestAppletAuthorize:FATAuthorizationTypeLocationBackground appletId:self.appletInfo.appId complete:^(NSInteger status) {
        NSInteger SDKSatus = status;
        if (status == 3) {
            //定位功能可用
            [[FATExt_locationAuthManager shareInstance] fat_requestAppletLocationAuthorize:self.appletInfo isBackground:YES withComplete:^(BOOL status) {
                if (status) {
                    [FATExt_LocationUpdateManager sharedManager].context = self.context;
                    [[FATExt_LocationUpdateManager sharedManager] startLocationUpdateType:self.type isAllowsBackgroundLocationUpdates:SDKSatus == 3 ? YES : NO withAppId:self.appletInfo.appId Success:success failure:failure cancel:cancel];
                } else {
                    if (failure) {
                        failure(@{@"errMsg" : @"system permission denied"});
                    }
                }
            }];
        } else if (status == 2) {
//            [[FATExt_LocationUpdateManager sharedManager] stopLocationUpdate];
            if (failure) {
                failure(@{@"errMsg" : @"unauthorized,用户未授予位置权限"});
            }
        } else if (status == 1) {
//            [[FATExt_LocationUpdateManager sharedManager] stopLocationUpdate];
            if (failure) {
                failure(@{@"errMsg" : @"unauthorized,用户未授予后台定位权限"});
            }
        } else {
//            [[FATExt_LocationUpdateManager sharedManager] stopLocationUpdate];
            if (failure) {
                failure(@{@"errMsg" : @"unauthorized disableauthorized,SDK被禁止申请位置权限"});
            }
        }
    }];
}


@end
