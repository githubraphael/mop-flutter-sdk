//
//  FATLocationManager.m
//  FinApplet
//
//  Created by Haley on 2020/4/7.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import "FATLocationManager.h"
#import "FATWGS84ConvertToGCJ02.h"
#import "FATExtLocationManager.h"

static FATLocationManager *instance = nil;

@interface FATLocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) FATExtLocationManager *locationManager;

@end

@implementation FATLocationManager

+ (instancetype)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FATLocationManager alloc] init];
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

- (void)updateLocation {
    if (![FATExtLocationManager locationServicesEnabled]) {
        return;
    }

    CLAuthorizationStatus status = [FATExtLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways ||
        status == kCLAuthorizationStatusNotDetermined) {
        //定位功能可用
        FATExtLocationManager *locationManager = [[FATExtLocationManager alloc] init];
        self.locationManager = locationManager;
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [locationManager requestWhenInUseAuthorization];
        [locationManager startUpdatingLocation];

    } else if (status == kCLAuthorizationStatusDenied) {
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *newLocation = [locations firstObject];
    //判断是不是属于国内范围
    if (![FATWGS84ConvertToGCJ02ForAMapView isLocationOutOfChina:[newLocation coordinate]]) {
        //转换后的coord
        CLLocationCoordinate2D coord = [FATWGS84ConvertToGCJ02ForAMapView transformFromWGSToGCJ:[newLocation coordinate]];
        newLocation = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    }
    self.location = newLocation;

    [self.locationManager stopUpdatingLocation];

    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray<CLPlacemark *> *_Nullable placemarks, NSError *_Nullable error) {
        if (error) {
            return;
        }

        if (placemarks.count > 0) {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            self.placemark = placemark;
            //            //获取省份
            //            NSString *province = placemark.administrativeArea;
            //            // 位置名
            //            NSLog(@"name,%@", placemark.name);
            //            // 街道
            //            NSLog(@"thoroughfare,%@", placemark.thoroughfare);
            //            // 子街道
            //            NSLog(@"subThoroughfare,%@", placemark.subThoroughfare);
            //            // 市
            //            NSLog(@"locality,%@", placemark.locality);
            //            // 区
            //            NSLog(@"subLocality,%@", placemark.subLocality);
            //            // 国家
            //            NSLog(@"country,%@", placemark.country);
        }
    }];
}

@end
