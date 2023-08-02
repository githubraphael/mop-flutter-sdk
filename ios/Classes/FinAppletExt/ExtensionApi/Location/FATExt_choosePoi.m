//
//  FATExt_choosePoi.m
//  FinAppletExt
//
//  Created by 王兆耀 on 2021/12/7.
//

#import "FATExt_choosePoi.h"
#import "FATLocationManager.h"
#import "FATWGS84ConvertToGCJ02.h"
#import "FATClient+ext.h"
#import "FATExtChoosePoiViewController.h"
#import "FATExtMapManager.h"
#import "FATExtNavigationController.h"
#import "FATExt_locationAuthManager.h"
#import <FinApplet/FinApplet.h>

@implementation FATExt_choosePoi

- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
    //    FATAppletInfo *appInfo = [[FATClient sharedClient] currentApplet];
    //如果使用的是百度地图sdk，需要调用百度地图的API方法
    NSString *mapClassStr = NSStringFromClass([FATExtMapManager shareInstance].mapClass);
    NSString *apiName = nil;
    if ([mapClassStr isEqualToString:@"FATBDMapView"]) {
        apiName = @"FATBDExt_choosePoi";
    } else if ([mapClassStr isEqualToString:@"FATTXMapView"]) {
        apiName = @"FATTXExt_choosePoi";
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
                    [self callChooseLocationWithWithSuccess:success failure:failure cancel:cancel];
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


- (void)callChooseLocationWithWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                                  failure:(void (^)(NSDictionary *failResult))failure
                                   cancel:(void (^)(NSDictionary *cancelResult))cancel {
    // 弹出定位选择界面
    UIViewController *topVC = [[UIApplication sharedApplication] fat_topViewController];

    FATExtChoosePoiViewController *mapVC = [[FATExtChoosePoiViewController alloc] init];
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
