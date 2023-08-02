//
//  FATExt_LocationUpdateManager.m
//  FinAppletExt
//
//  Created by 王兆耀 on 2022/11/6.
//

#import "FATExt_LocationUpdateManager.h"
#import <FinApplet/FinApplet.h>
#import "FATWGS84ConvertToGCJ02.h"

#import <FinApplet/FinApplet.h>

static FATExt_LocationUpdateManager *instance = nil;


NSString *const FATExtAppletUpdateBackgroudPermissions = @"FATAppletUpdateBackgroudPermissions";

@interface FATExt_LocationUpdateManager ()<CLLocationManagerDelegate>


@property (nonatomic, copy) NSString *type;

@property (nonatomic, copy) void (^success)(NSDictionary<NSString *, id> *_Nonnull);
@property (nonatomic, copy) void (^failure)(NSDictionary *_Nullable);
@property (nonatomic, copy) void (^cancel)(NSDictionary *_Nullable);

@end

@implementation FATExt_LocationUpdateManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //小程序关闭通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appletClose:) name:FATAppletDestroyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(permissionsUpdate:) name:FATExtAppletUpdateBackgroudPermissions object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appletEnterBackground:) name:FATAppletEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidForeground:) name:FATAppletForegroundNotification object:nil];
    }
    
    return self;
}

#pragma 通知的相关处理
- (void)appletClose:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSString *appletId = [dic objectForKey:@"appletId"];
    // 关闭小程序时，需要停止获取定位。
    if (appletId && [appletId isEqualToString:self.appletId] && self.locationIsInit) {
        [self stopLocationUpdate];
    }
}

- (void)permissionsUpdate:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSInteger type = [[dic objectForKey:@"type"] integerValue];
    if (type == 0 ) {
        [self stopLocationUpdate];
    }
    if (_locationManager.allowsBackgroundLocationUpdates && self.locationIsInit) {
        if (type == 1) {
            [self stopLocationUpdate];
        }
    }
}

- (void)appletEnterBackground:(NSNotification *)notification {
    if (!_locationManager.allowsBackgroundLocationUpdates && self.locationIsInit) {
        [_locationManager stopUpdatingLocation];
    }
}

- (void)appDidForeground:(NSNotification *)notification {
    if (!_locationManager.allowsBackgroundLocationUpdates && self.locationIsInit) {
        if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)) {
            [_locationManager startUpdatingLocation];
        }
    }
}

- (void)checkLocationState {
    if (self.locationIsInit) {
        // 胶囊按钮
        UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
        UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
        if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
            [nav controlCapsuleStateButton:NO state:FATCapsuleButtonStateLocation animate:YES];
        }
    }
}


- (void)startLocationUpdateType:(NSString *)type isAllowsBackgroundLocationUpdates:(BOOL)result withAppId:(NSString *)appId Success:(void (^)(NSDictionary<NSString *, id> *successResult))success
                        failure:(void (^)(NSDictionary *failResult))failure
                         cancel:(void (^)(NSDictionary *cancelResult))cancel {
    // 如果已经初始化了，并且参数一致，就终止
    if (self.locationIsInit && _locationManager.allowsBackgroundLocationUpdates == result) {
        return;
    }
    //定位功能可用
    _locationManager = [[FATExtLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.allowsBackgroundLocationUpdates = result;
    _locationManager.pausesLocationUpdatesAutomatically = YES;
    [_locationManager requestWhenInUseAuthorization];
    self.type = type;
    self.locationIsInit = YES;
    if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)) {
        [self onLocationUpdate];
    }
    self.appletId = appId;
    self.success = success;
    self.failure = failure;
}

- (void)onLocationUpdate {
    [_locationManager startUpdatingLocation];
}

- (void)stopLocationUpdate {
    [_locationManager stopUpdatingLocation];
    if (self.context) {
        [self.context sendResultEvent:0 eventName:@"offLocationChange" eventParams:@{} extParams:nil];
    }
    self.appletId = @"";
    self.locationIsInit = NO;
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *newLocation = [locations objectAtIndex:0];
    // 把默认值改为gcj02
    NSString *typeString = @"gcj02";
    CLLocationCoordinate2D coord = [FATWGS84ConvertToGCJ02ForAMapView transformFromWGSToGCJ:[newLocation coordinate]];
    newLocation = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    
    if ([self.type isEqualToString:@"wgs84"]) {
        CLLocationCoordinate2D coord = [FATWGS84ConvertToGCJ02ForAMapView transformFromGCJToWGS:[newLocation coordinate]];
        newLocation = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
        typeString = @"wgs84";
    }
    
    CLLocationCoordinate2D coordinate = newLocation.coordinate;
    NSDictionary *params = @{@"altitude" : @(newLocation.altitude),
                             @"latitude" : @(coordinate.latitude),
                             @"longitude" : @(coordinate.longitude),
                             @"speed" : @(newLocation.speed),
                             @"accuracy" : @(newLocation.horizontalAccuracy),
                             @"type" : typeString,
                             @"verticalAccuracy" : @(newLocation.verticalAccuracy),
                             @"horizontalAccuracy" : @(newLocation.horizontalAccuracy)
    };
    if (self.context) {
        [self.context sendResultEvent:0 eventName:@"onLocationChange" eventParams:params extParams:nil];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (self.context) {
        [self.context sendResultEvent:0 eventName:@"onLocationChangeError" eventParams:@{} extParams:nil];
    }
    [self stopLocationUpdate];
    if (self.failure) {
        self.failure(@{});
    }
}

//- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
//    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
//        [self onLocationUpdate];
//        if (self.success) {
//            self.success(@{});
//        }
//    } else {
//        if (self.failure) {
//            self.failure(@{@"errMsg" : @"system permission denied"});
//        }
//        [self stopLocationUpdate];
//    }
//}

@end
