//
//  FATExt_chooseLocation.m
//  FinAppletExt
//
//  Created by Haley on 2020/8/19.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import "FATExt_chooseLocation.h"
#import "FATMapViewController.h"
#import "FATClient+ext.h"
#import "FATExtMapManager.h"
#import "FATExtNavigationController.h"
#import "FATExt_locationAuthManager.h"
#import <CoreLocation/CoreLocation.h>

@implementation FATExt_chooseLocation

- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
//    if (![CLLocationManager locationServicesEnabled]) {
//        if (callback) {
//            callback(FATExtensionCodeFailure, @{@"errMsg" : @"location service not open"});
//        }
//        return;
//    }
    NSString *mapClassStr = NSStringFromClass([FATExtMapManager shareInstance].mapClass);
    NSString *apiName = nil;
    if ([mapClassStr isEqualToString:@"FATBDMapView"]) {
        apiName = @"FATBDExt_chooseLocation";
    } else if ([mapClassStr isEqualToString:@"FATTXMapView"]) {
        apiName = @"FATTXExt_chooseLocation";
    } else if ([mapClassStr isEqualToString:@"FATGDMapView"]) {
        apiName = @"FATGDExt_chooseLocation";
    }
    if (apiName) {
        id<FATApiProtocol> api = [self.class fat_apiWithApiClass:apiName params:self.param];
        if (api) {
            api.appletInfo = self.appletInfo;
            api.context = self.context;
            [api setupApiWithSuccess:success failure:failure cancel:cancel];
            return;
        }
    }

    [[FATClient sharedClient] fat_requestAppletAuthorize:FATAuthorizationTypeLocation appletId:self.appletInfo.appId complete:^(NSInteger status) {
        if (status == 0) {
            [[FATExt_locationAuthManager shareInstance] fat_requestAppletLocationAuthorize:self.appletInfo isBackground:NO withComplete:^(BOOL status) {
                if (status) {
                    [self callChooseLocationWithSuccess:success failure:failure cancel:cancel];
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

- (void)callChooseLocationWithSuccess:(void (^)(NSDictionary<NSString *, id> *_Nonnull))success failure:(void (^)(NSDictionary *_Nullable))failure cancel:(void (^)(NSDictionary *cancelResult))cancel {
    // 弹出定位选择界面
    UIViewController *topVC = [[UIApplication sharedApplication] fat_topViewController];

    FATMapViewController *mapVC = [[FATMapViewController alloc] init];
    mapVC.latitude = self.latitude;
    mapVC.longitude = self.longitude;
    mapVC.cancelBlock = ^{
        cancel(nil);
    };
    mapVC.sureBlock = ^(NSDictionary *locationInfo) {
        success(locationInfo);
    };
    FATExtNavigationController *nav = [[FATExtNavigationController alloc] initWithRootViewController:mapVC];
    if (@available(iOS 15, *)) {
        UINavigationBarAppearance *barAppearance = [[UINavigationBarAppearance alloc] init];
        [barAppearance configureWithOpaqueBackground];
        barAppearance.backgroundColor = [UIColor whiteColor];
        nav.navigationBar.standardAppearance = barAppearance;
        nav.navigationBar.scrollEdgeAppearance = barAppearance;
    }

    [topVC presentViewController:nav animated:YES completion:nil];
}

@end
