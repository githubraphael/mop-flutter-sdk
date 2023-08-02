//
//  FATMapViewController.m
//  AppletDemo
//
//  Created by Haley on 2020/4/16.
//  Copyright © 2020 weidian. All rights reserved.
//

#import "FATMapViewController.h"
#import "FATLocationResultViewController.h"
#import "FATAnnotation.h"
#import "FATExtHelper.h"
#import "FATExtSliderView.h"
#import "FATWGS84ConvertToGCJ02.h"
#import "FATExtLocationManager.h"
#import <MapKit/MapKit.h>
#import "UIView+FATExtSafaFrame.h"

#define fatKScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define fatKScreenHeight ([UIScreen mainScreen].bounds.size.height)

static NSString *kAnnotationId = @"FATAnnotationViewId";
static NSString *kUserAnnotationId = @"FATUserAnnotationViewId";


@interface FATMapViewController () <MKMapViewDelegate, CLLocationManagerDelegate, FATLocationResultDelegate>

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) MKUserLocation *userLocation;
@property (nonatomic, strong) UIButton *returnButton;
@property (nonatomic, strong) UIButton *determineButton;
@property (nonatomic, strong) UIButton *positionButton;
@property (nonatomic, strong) FATExtSliderView *slideView;
@property (nonatomic, strong) FATMapPlace *poiInfo;
@property (nonatomic, strong) MKPointAnnotation *centerAnnotation;
@property (nonatomic, strong) FATExtLocationManager *locationManager;

@end

@implementation FATMapViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    _mapView.showsUserLocation = NO;
    _mapView.userTrackingMode = MKUserTrackingModeNone;
    [_mapView.layer removeAllAnimations];
    [_mapView removeAnnotations:self.mapView.annotations];
    [_mapView removeOverlays:self.mapView.overlays];
    [_mapView removeFromSuperview];
    _mapView.delegate = nil;
    _mapView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.edgesForExtendedLayout = UIRectEdgeNone;

    [self p_initSubViews];

    [self settingMapCenter];
}

- (void)dealloc {
    _mapView.showsUserLocation = NO;
    _mapView.userTrackingMode = MKUserTrackingModeNone;
    [_mapView.layer removeAllAnimations];
    [_mapView removeAnnotations:self.mapView.annotations];
    [_mapView removeOverlays:self.mapView.overlays];
    [_mapView removeFromSuperview];
    _mapView.delegate = nil;
    _mapView = nil;
}

- (void)p_initSubViews {
    // 判断是否是暗黑模式
    BOOL isDark = false;
    if (@available(iOS 12.0, *)) {
        isDark = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
    }
    self.view.backgroundColor = isDark ? UIColor.blackColor : UIColor.whiteColor;
    [self.view addSubview:self.mapView];
    self.mapView.frame = CGRectMake(0, 0, fatKScreenWidth, fatKScreenHeight - 200);

    self.centerAnnotation = [[MKPointAnnotation alloc] init];
    self.centerAnnotation.coordinate = self.mapView.centerCoordinate;
    [self.mapView addAnnotation:self.centerAnnotation];

    CGFloat top = [UIView  fat_statusHeight];
    self.returnButton = [[UIButton alloc] initWithFrame:CGRectMake(16, top, 57, 32)];
    [self.returnButton setImage:[FATExtHelper fat_ext_imageFromBundleWithName:@"map_back_n"] forState:UIControlStateNormal];
    [self.returnButton addTarget:self action:@selector(cancelItemClick) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:self.returnButton];

    self.determineButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 16 - 57, top, 57, 32)];
    NSString *ok = [[FATClient sharedClient] fat_localizedStringForKey:@"OK"];
    [self.determineButton setTitle:ok forState:UIControlStateNormal];
    [self.determineButton setTitleColor:[UIColor colorWithRed:255 / 255.0 green:255 / 255.0 blue:255 / 255.0 alpha:1 / 1.0] forState:UIControlStateNormal];
    [self.determineButton setBackgroundColor:[UIColor colorWithRed:64 / 255.0 green:158 / 255.0 blue:255 / 255.0 alpha:1 / 1.0]];
    [self.determineButton addTarget:self action:@selector(sureItemClick) forControlEvents:UIControlEventTouchUpInside];
    self.determineButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [self.mapView addSubview:self.determineButton];

    self.positionButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 73, fatKScreenHeight - 260, 45, 45)];

    if (isDark) {
        [self.positionButton setImage:[FATExtHelper fat_ext_imageFromBundleWithName:@"map_location_dn"] forState:UIControlStateNormal];
        [self.positionButton setImage:[FATExtHelper fat_ext_imageFromBundleWithName:@"map_location_dp"] forState:UIControlStateHighlighted];
        self.mapView.mapType = MKMapTypeStandard;
    } else {
        [self.positionButton setImage:[FATExtHelper fat_ext_imageFromBundleWithName:@"map_location_ln"] forState:UIControlStateNormal];
        [self.positionButton setImage:[FATExtHelper fat_ext_imageFromBundleWithName:@"map_location_lp"] forState:UIControlStateHighlighted];
        self.mapView.mapType = MKMapTypeStandard;
    }
    [self.positionButton addTarget:self action:@selector(locationOnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:self.positionButton];
    __weak typeof(self) weakSelf = self;
    self.slideView = [[FATExtSliderView alloc] initWithFrame:CGRectMake(0, fatKScreenHeight - 200, fatKScreenWidth, fatKScreenHeight - 250)];
    self.slideView.backgroundColor = isDark ? UIColor.blackColor : UIColor.whiteColor;
    self.slideView.tableView.backgroundColor = isDark ? UIColor.blackColor : UIColor.whiteColor;
    self.slideView.topH = 300;
    self.slideView.selectItemBlock = ^(FATMapPlace *locationInfo) {
        CLLocationCoordinate2D centerCoord = {locationInfo.location.coordinate.latitude, locationInfo.location.coordinate.longitude};
        weakSelf.poiInfo = locationInfo;
        [UIView animateWithDuration:1 animations:^{
            weakSelf.centerAnnotation.coordinate = centerCoord;
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(centerCoord, 1000, 1000);
            weakSelf.mapView.centerCoordinate = centerCoord;
            weakSelf.mapView.region = region;
        }];
    };

    if ([self.latitude isEqualToString:@"nil"] || [self.longitude isEqualToString:@"nil"] || (!self.latitude && !self.longitude)) {
        [self startStandardUpdates];
    } else {
        CLLocationCoordinate2D centerCoord = {[self.latitude doubleValue], [self.longitude doubleValue]};
        self.mapView.centerCoordinate = centerCoord;
        [self.slideView updateSearchFrameWithColcationCoordinate:self.mapView.centerCoordinate];
    }
    __block float heights = fatKScreenHeight - 200;
    __block float positionButtonY = fatKScreenHeight - 260;
    self.slideView.topDistance = ^(float height, BOOL isTopOrBottom) {
        if (!isTopOrBottom) {
            heights += height;
            positionButtonY += height;
        } else {
            heights = height;
            positionButtonY = height;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.mapView.frame = CGRectMake(0, 0, fatKScreenWidth, heights);
            weakSelf.positionButton.frame = CGRectMake(self.view.frame.size.width - 73, positionButtonY > fatKScreenHeight - 260 ? fatKScreenHeight - 260 : positionButtonY, 45, 45);
            if (heights + weakSelf.slideView.frame.size.height < fatKScreenHeight) {
                weakSelf.mapView.frame = CGRectMake(0, 0, fatKScreenWidth, fatKScreenHeight - weakSelf.slideView.frame.size.height);
                weakSelf.positionButton.frame = CGRectMake(self.view.frame.size.width - 73, fatKScreenHeight - 260, 45, 45);
            }
        });
    };
    [self.view addSubview:self.slideView];
}

- (void)locationOnClick {
    [self startStandardUpdates];
}

- (void)startStandardUpdates {
//    if (![FATExtLocationManager locationServicesEnabled]) {
//        return;
//    }
    
    CLAuthorizationStatus status = [FATExtLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways ||
        status == kCLAuthorizationStatusNotDetermined) {
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager startUpdatingLocation];
    }
}

- (void)settingMapCenter {
    if ([NSString fat_isEmptyWithString:self.latitude] || [NSString fat_isEmptyWithString:self.longitude]) {
        return;
    }

    double LongitudeDelta = [self fat_getLongitudeDelta:14.00];
//    double LatitudeDelta = LongitudeDelta * 2;
    CLLocationCoordinate2D centerCoord = {[self judgeLatition:[self.latitude doubleValue]], [self judgeLongitude:[self.longitude doubleValue]]};
    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoord, MKCoordinateSpanMake(LongitudeDelta, LongitudeDelta));

    [self.mapView setRegion:region animated:YES];
}

#pragma mark - click events
- (void)cancelItemClick {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    if (self.cancelBlock) {
        self.cancelBlock();
    }
}

- (void)sureItemClick {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    if (self.poiInfo == nil && self.slideView.poiInfoListArray.count > 0) {
        self.poiInfo = self.slideView.poiInfoListArray.firstObject;
    }

    CLLocationCoordinate2D coordinate = self.poiInfo.location.coordinate;
    NSDictionary *locationInfo = @{@"name" : self.poiInfo.name ?: @"",
                                   @"address" : self.poiInfo.address ?: @"",
                                   @"latitude" : @(coordinate.latitude),
                                   @"longitude" : @(coordinate.longitude)};
    if (self.sureBlock) {
        self.sureBlock(locationInfo);
    }
}

#pragma mark - FATLocationResultDelegate
- (void)selectedLocationWithLocation:(FATMapPlace *)place {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(place.location.coordinate, 1000, 1000);
    self.mapView.centerCoordinate = place.location.coordinate;
    self.mapView.region = region;
}

#pragma mark - MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if (!self.userLocation) {
        _userLocation = userLocation;
        CLLocationCoordinate2D center = [FATWGS84ConvertToGCJ02ForAMapView transformFromWGSToGCJ:userLocation.location.coordinate];
        if (center.latitude > 0 && center.longitude > 0) {
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(center, 1000, 1000);
            if ([NSString fat_isEmptyWithString:self.latitude] || [NSString fat_isEmptyWithString:self.longitude]) {
                mapView.centerCoordinate = center;
                mapView.region = region;
                [self.mapView setRegion:region animated:YES];
                self.centerAnnotation.coordinate = center;
            }
        }
        [self.slideView updateSearchFrameWithColcationCoordinate:center];
    }
}

/**
 *  更新到位置之后调用
 *
 *  @param manager   位置管理者
 *  @param locations 位置数组
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations firstObject];
    //位置更新后的经纬度
    CLLocationCoordinate2D theCoordinate = location.coordinate;
    //设置地图显示的中心及范围
    MKCoordinateRegion theRegion;
    theRegion.center = theCoordinate;
    CLLocationCoordinate2D coord = [FATWGS84ConvertToGCJ02ForAMapView transformFromWGSToGCJ:theCoordinate];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coord, 1000, 1000);
    [self.mapView setRegion:region animated:YES];
    self.centerAnnotation.coordinate = coord;
    [self.locationManager stopUpdatingLocation];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CLLocationCoordinate2D centerCoordinate = self.mapView.centerCoordinate;
//    CLLocationCoordinate2D centerCoordinate = self.centerAnnotation.coordinate;
    [self.slideView updateSearchFrameWithColcationCoordinate:centerCoordinate];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    CLLocationCoordinate2D centerCoordinate = mapView.centerCoordinate;
    [UIView animateWithDuration:1 animations:^{
        self.centerAnnotation.coordinate = centerCoordinate;
    }];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }

    static NSString *ID = @"anno";
    MKPinAnnotationView *annoView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:ID];
    if (annoView == nil) {
        annoView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ID];
        // 显示气泡
        annoView.canShowCallout = YES;
        // 设置绿色
    }

    return annoView;
}

- (double)fat_getLongitudeDelta:(double)scale {
    double longitudeDelta = (360 * self.mapView.frame.size.width / 256.0 / pow(2, scale));
    return longitudeDelta;
}

// 校验经度是否合规
- (double)judgeLatition:(double)latitude {
    if (latitude >= 90) {
        latitude = 85.00;
    }
    if (latitude <= -90) {
        latitude = -85.00;
    }
    return latitude;
}
// 校验纬度是否合规
- (double)judgeLongitude:(double)longitude {
    if (longitude >= 180) {
        longitude = 180.00;
    }
    if (longitude <= -180) {
        longitude = -180.00;
    }
    return longitude;
}

- (FATExtLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[FATExtLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (MKMapView *)mapView {
    if (!_mapView) {
        _mapView = [[MKMapView alloc] init];
        _mapView.delegate = self;
        _mapView.mapType = MKMapTypeStandard;
        _mapView.showsUserLocation = YES;
        _mapView.userTrackingMode = MKUserTrackingModeNone;
    }
    return _mapView;
}

@end
