//
//  FATExt_getLocation.m
//  FinAppletExt
//
//  Created by Haley on 2020/12/10.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import "FATExt_getLocation.h"
#import "FATLocationManager.h"
#import "FATWGS84ConvertToGCJ02.h"
#import "FATClient+ext.h"
#import "FATExtLocationManager.h"
#import "FATExtMapManager.h"
#import "FATExt_locationAuthManager.h"
#import <FinApplet/FinApplet.h>

@interface FATExt_getLocation () <CLLocationManagerDelegate>

@property (nonatomic, strong) FATExtLocationManager *locationManager;

@property (nonatomic, strong) FATExtBaseApi *strongSelf;
@property (nonatomic, copy) void (^success)(NSDictionary<NSString *, id> *_Nonnull);
@property (nonatomic, copy) void (^failure)(NSDictionary *_Nullable);
@property (nonatomic, strong) NSTimer *locationUpdateTimer;

@end

@implementation FATExt_getLocation

- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
    
    NSString *mapClassStr = NSStringFromClass([FATExtMapManager shareInstance].mapClass);
    NSString *apiName = nil;
    if ([mapClassStr isEqualToString:@"FATBDMapView"]) {
        apiName = @"FATBDExt_getLocation";
    } else if ([mapClassStr isEqualToString:@"FATTXMapView"]) {
        apiName = @"FATTXExt_getLocation";
    } else if ([mapClassStr isEqualToString:@"FATGDMapView"]) {
        apiName = @"FATGDExt_getLocation";
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
    
    self.success = success;
    self.failure = failure;
//    FATAppletInfo *appInfo = [[FATClient sharedClient] currentApplet];
    [[FATClient sharedClient] fat_requestAppletAuthorize:FATAuthorizationTypeLocation appletId:self.appletInfo.appId complete:^(NSInteger status) {
        if (status == 0) {
            //定位功能可用
            [[FATExt_locationAuthManager shareInstance] fat_requestAppletLocationAuthorize:self.appletInfo isBackground:NO withComplete:^(BOOL status) {
                if (status) {
                    [self startUpdateLocation];
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

- (void)startUpdateLocation {
    _locationManager = [[FATExtLocationManager alloc] init];
    _locationManager.delegate = self;
    if (self.isHighAccuracy) {
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    } else {
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    }
    [_locationManager requestWhenInUseAuthorization];
    [_locationManager startUpdatingLocation];
    
    _strongSelf = self;
    __weak typeof(self) weak_self = self;
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 10);
    dispatch_after(time, dispatch_get_global_queue(0, 0), ^{
        weak_self.strongSelf = nil;
    });
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *newLocation = [locations objectAtIndex:0];
    NSString *typeString = @"wgs84";
    //判断是不是属于国内范围
    if ([self.type isEqualToString:@"gcj02"]) {
        //转换后的coord
        CLLocationCoordinate2D coord = [FATWGS84ConvertToGCJ02ForAMapView transformFromWGSToGCJ:[newLocation coordinate]];
        newLocation = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
        typeString = @"gcj02";
    }
    
    [FATLocationManager manager].location = newLocation;
    CLLocationCoordinate2D coordinate = newLocation.coordinate;

    if (self.success) {
        NSDictionary *params = @{@"altitude" : @(newLocation.altitude),
                                 @"latitude" : @(coordinate.latitude),
                                 @"longitude" : @(coordinate.longitude),
                                 @"speed" : @(newLocation.speed),
                                 @"accuracy" : @(newLocation.horizontalAccuracy),
                                 @"type" : typeString,
                                 @"verticalAccuracy" : @(newLocation.verticalAccuracy),
                                 @"horizontalAccuracy" : @(newLocation.horizontalAccuracy)
        };
        NSMutableDictionary *dataDic = [[NSMutableDictionary alloc] initWithDictionary:params];
        if (!self.altitude) {
            [dataDic removeObjectForKey:@"altitude"];
        }
        self.success(dataDic);
    }

    [_locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (self.failure) {
        self.failure(nil);
    }
}

@end
