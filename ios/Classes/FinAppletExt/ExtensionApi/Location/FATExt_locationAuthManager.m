//
//  FATExt_locationAuthManager.m
//  FinAppletExt
//
//  Created by 王兆耀 on 2022/12/24.
//

#import "FATExt_locationAuthManager.h"
#import <CoreLocation/CoreLocation.h>


@interface FATExt_locationAuthManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) NSMutableArray *locationAuthCompleteArray;

@property (nonatomic, strong) NSMutableArray<FATAppletInfo*> *appletInfoArray;
@property (nonatomic, strong) NSMutableDictionary *authTypeDic; //key是小程序Id value是权限类型，用来区分后台定位和正常位置权限
@end

static FATExt_locationAuthManager *instance = nil;

@implementation FATExt_locationAuthManager

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FATExt_locationAuthManager alloc] init];
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
        [self p_init];
    }
    return self;
}

- (void)p_init {
    _locationAuthCompleteArray = [NSMutableArray array];
    _appletInfoArray = [[NSMutableArray alloc]init];
    _authTypeDic = [[NSMutableDictionary alloc]init];
}

- (void)fat_requestAppletLocationAuthorize:(FATAppletInfo *)appletInfo isBackground:(BOOL)isBackground withComplete:(void (^)(BOOL status))complete {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [self notifyApp:appletInfo authType:isBackground ? FATAuthorizationTypeLocationBackground : FATAuthorizationTypeLocation authResult:FATAuthorizationStatusAuthorized];
        if (complete) {
            complete(YES);
        }
        return;
    }
    
    if (status != kCLAuthorizationStatusNotDetermined) {
        [self notifyApp:appletInfo authType:isBackground ? FATAuthorizationTypeLocationBackground : FATAuthorizationTypeLocation authResult:FATAuthorizationStatusDenied];
        if (complete) {
            complete(NO);
        }
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.locationAuthCompleteArray addObject:complete];
        if (appletInfo) {
            [self.appletInfoArray addObject:appletInfo];
            if (appletInfo.appId) {
                [self.authTypeDic setValue:isBackground ? @(FATAuthorizationTypeLocationBackground) : @(FATAuthorizationTypeLocation) forKey:appletInfo.appId];
            }
        }
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager requestWhenInUseAuthorization];
    });
    return;
}

- (void)notifyApp:(FATAppletInfo *)appletInfo authType:(FATAuthorizationType)type authResult:(FATAuthorizationStatus)result {
    id<FATAppletAuthDelegate> delegate = [FATClient sharedClient].authDelegate;
    if (delegate && [delegate respondsToSelector:@selector(applet:didRequestAuth:withResult:)]) {
        [delegate applet:appletInfo didRequestAuth:type withResult:result];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusNotDetermined) {
        return;
    }
    for (FATAppletInfo *appInfo in self.appletInfoArray) {
        FATAuthorizationStatus authStatus = FATAuthorizationStatusDenied;
        if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
            authStatus = FATAuthorizationStatusAuthorized;
        }
        NSNumber *authtype = [self.authTypeDic objectForKey:appInfo.appId];
        FATAuthorizationType type = FATAuthorizationTypeLocation;
        if (authtype) {
            type = [authtype integerValue];
        }
        [self notifyApp:appInfo authType:type authResult:authStatus];
    }
    [self.appletInfoArray removeAllObjects];
    [self.authTypeDic removeAllObjects];
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        for (int i = 0; i < self.locationAuthCompleteArray.count; i++) {
            void(^locationComplete)(BOOL status) = self.locationAuthCompleteArray[i];
            locationComplete(YES);
        }
        [self.locationAuthCompleteArray removeAllObjects];
        return;
    }
    
    for (int i = 0; i < self.locationAuthCompleteArray.count; i++) {
        void(^locationComplete)(BOOL status) = self.locationAuthCompleteArray[i];
        locationComplete(NO);
    }
    
    [self.locationAuthCompleteArray removeAllObjects];
}


@end

