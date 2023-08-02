//
//  FATExt_openLocation.m
//  FinAppletExt
//
//  Created by 王兆耀 on 2021/12/7.
//

#import "FATExt_openLocation.h"
#import "FATWGS84ConvertToGCJ02.h"
#import "FATClient+ext.h"
#import "FATOpenLocationViewController.h"
#import "FATExtMapManager.h"
#import "FATExtNavigationController.h"
#import "FATExt_locationAuthManager.h"
#import <FinApplet/FinApplet.h>

@implementation FATExt_openLocation

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
        apiName = @"FATBDExt_openLocation";
    } else if ([mapClassStr isEqualToString:@"FATGDMapView"]) {
        apiName = @"FATGDExt_openLocation";
    } else if ([mapClassStr isEqualToString:@"FATTXMapView"]) {
        apiName = @"FATTXExt_openLocation";
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
            //定位功能可用
            [[FATExt_locationAuthManager shareInstance] fat_requestAppletLocationAuthorize:self.appletInfo isBackground:NO withComplete:^(BOOL status) {
                if (status) {
                    [self callChooseLocationWithCallback];
                    if (success) {
                        success(@{});
                    }
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

- (void)callChooseLocationWithCallback {
    // 弹出定位选择界面
    UIViewController *topVC = [[UIApplication sharedApplication] fat_topViewController];

    FATOpenLocationViewController *mapVC = [[FATOpenLocationViewController alloc] init];
    mapVC.latitude = self.latitude;
    mapVC.longitude = self.longitude;
    mapVC.scale = self.scale;
    mapVC.name = self.name ? self.name : @"[位置]";
    mapVC.address = self.address;
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
