//
//  FATOpenLocationViewController.m
//  FinAppletExt
//
//  Created by 王兆耀 on 2021/12/9.
//

#import "FATOpenLocationViewController.h"
#import "FATExtHelper.h"
#import "MKMarkerView.h"
#import "FATExtLocationManager.h"
#import "FATWGS84ConvertToGCJ02.h"
#import "FATExtUtil.h"

#import <MapKit/MapKit.h>

@interface FATOpenLocationViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) MKMapView *mapView;

@property (nonatomic, strong) UIButton *locationButton;

@property (nonatomic, strong) UIButton *returnButton;

@property (nonatomic, strong) FATExtLocationManager *locationManager;

@property (nonatomic, assign) double Delta;

@end

@implementation FATOpenLocationViewController

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

- (FATExtLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[FATExtLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self fatCreatUI];

    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, self.view.frame.size.height)];
    view.backgroundColor = UIColor.clearColor;
    [self.view addSubview:view];

    UIScreenEdgePanGestureRecognizer *edgeGes = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(edgePan:)];
    edgeGes.edges = UIRectEdgeLeft;
    [view addGestureRecognizer:edgeGes];
}

- (void)dealloc {
//    _mapView.showsUserLocation = NO;
//    _mapView.userTrackingMode = MKUserTrackingModeNone;
    [_mapView.layer removeAllAnimations];
    [_mapView removeAnnotations:self.mapView.annotations];
    [_mapView removeOverlays:self.mapView.overlays];
    [_mapView removeFromSuperview];
    _mapView.delegate = nil;
    _mapView = nil;
}

- (void)edgePan:(UIPanGestureRecognizer *)recognizer {
    [self dismissViewControllerAnimated:YES completion:^{

    }];
}

- (void)fatCreatUI {
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    CGFloat bottomViewHeight = 100;

    self.mapView.frame = CGRectMake(0, 0, width, height);
    [self.view addSubview:self.mapView];

    CGFloat top = [UIView  fat_statusHeight];
    self.returnButton = [[UIButton alloc] initWithFrame:CGRectMake(16, top, 50, 50)];
    [self.returnButton setImage:[FATExtHelper fat_ext_imageFromBundleWithName:@"map_back_n"] forState:UIControlStateNormal];
    [self.returnButton addTarget:self action:@selector(returnOnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:self.returnButton];

    self.locationButton = [[UIButton alloc] initWithFrame:CGRectMake(width - 48 - 16.5, height - bottomViewHeight - 24.5 - 48, 48, 48)];
    // 判断是否是暗黑模式
    BOOL isDark = false;
    if (@available(iOS 13.0, *)) {
        isDark = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
    }
    if (isDark) {
        [self.locationButton setImage:[FATExtHelper fat_ext_imageFromBundleWithName:@"map_location_dn"] forState:UIControlStateNormal];
        [self.locationButton setImage:[FATExtHelper fat_ext_imageFromBundleWithName:@"map_location_dp"] forState:UIControlStateHighlighted];
    } else {
        [self.locationButton setImage:[FATExtHelper fat_ext_imageFromBundleWithName:@"map_location_ln"] forState:UIControlStateNormal];
        [self.locationButton setImage:[FATExtHelper fat_ext_imageFromBundleWithName:@"map_location_lp"] forState:UIControlStateHighlighted];
    }
    [self.locationButton addTarget:self action:@selector(locationOnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:self.locationButton];

    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, height - bottomViewHeight, width, bottomViewHeight)];
    if (@available(iOS 13.0, *)) {
        bgView.backgroundColor = UIColor.systemGray6Color;
    } else {
        // Fallback on earlier versions
    }
    [self.mapView addSubview:bgView];
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 25.5, width - 70, 31)];
    nameLabel.font = [UIFont systemFontOfSize:22];
    nameLabel.text = self.name;
    nameLabel.textColor = isDark ? [UIColor colorWithRed:208 / 255.0 green:208 / 255.0 blue:208 / 255.0 alpha:1 / 1.0] : [UIColor colorWithRed:34 / 255.0 green:34 / 255.0 blue:34 / 255.0 alpha:1 / 1.0];
    [bgView addSubview:nameLabel];
    UILabel *addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 65.5, width - 70, 16.5)];
    addressLabel.font = [UIFont systemFontOfSize:12];
    addressLabel.text = self.address;
    addressLabel.textColor = UIColor.lightGrayColor;
    [bgView addSubview:addressLabel];

    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(bgView.frame.size.width - 70, bottomViewHeight / 2 - 25, 50, 50)];
    [button setImage:[FATExtHelper fat_ext_imageFromBundleWithName:@"map_navigation_n"] forState:UIControlStateNormal];
    [button setImage:[FATExtHelper fat_ext_imageFromBundleWithName:@"map_navigation_p"] forState:UIControlStateHighlighted];
    button.layer.cornerRadius = 25;
    [button addTarget:self action:@selector(navigationOnClick) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:button];

    double delta = [self.scale doubleValue];
    if (delta < 5) {
        delta = 5.00;
    }
    if (delta > 18) {
        delta = 18.00;
    }
    double LongitudeDelta = [self fat_getLongitudeDelta:delta];
    self.Delta = LongitudeDelta;
    CLLocationCoordinate2D centerCoord = {[self judgeLatition:[self.latitude doubleValue]], [self judgeLongitude:[self.longitude doubleValue]]};
    [self.mapView setRegion:MKCoordinateRegionMake(centerCoord, MKCoordinateSpanMake(LongitudeDelta, LongitudeDelta)) animated:YES];
    // 添加一个大头针
    MKMarker *marker = [[MKMarker alloc] init];
    marker.coordinate = centerCoord;
    [self.mapView addAnnotation:marker];
}

- (void)locationOnClick {
    [self startStandardUpdates];
}

- (void)returnOnClick {
    [self dismissViewControllerAnimated:YES completion:^{

    }];
}

- (void)startStandardUpdates {
    if (![FATExtLocationManager locationServicesEnabled]) {
        return;
    }

    CLAuthorizationStatus status = [FATExtLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways ||
        status == kCLAuthorizationStatusNotDetermined) {
        //定位功能可用

        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager startUpdatingLocation];

    } else if (status == kCLAuthorizationStatusDenied) {
    }
}

- (double)fat_getLongitudeDelta:(double)scale {
    double longitudeDelta = (360 * self.mapView.frame.size.width / 256.0 / pow(2, scale));
    return longitudeDelta;
}

- (void)navigationOnClick {
    [self fat_openMapApp:@{@"latitude" : self.latitude, @"longitude" : self.longitude, @"destination" : self.name}];
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
    CLLocationCoordinate2D coord = [FATWGS84ConvertToGCJ02ForAMapView transformFromWGSToGCJ:location.coordinate];
    CLLocation *newLocations = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    
    [self.mapView setRegion:MKCoordinateRegionMake(newLocations.coordinate, MKCoordinateSpanMake(self.Delta, self.Delta)) animated:YES];
    [self.locationManager stopUpdatingLocation];
}

- (nullable MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    // If the annotation is the user location, just return nil.（如果是显示用户位置的Annotation,则使用默认的蓝色圆点）
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    if ([annotation isKindOfClass:MKMarker.class]) {
        MKMarker *marker = (MKMarker *)annotation;
        MKAnnotationView *markerView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"markerView"];
        markerView.canShowCallout = YES;
        markerView.annotation = marker;
        markerView.image = marker.image;
        return markerView;
    }
    return nil;
}

- (void)fat_openMapApp:(NSDictionary *)data {
    /*
     常见app的url Scheme
     1.苹果自带地图（不需要检测，所以不需要URL Scheme）
     2.百度地图 ：baidumap
     3.高德地图 ：iosamap
     4.谷歌地图 ：comgooglemaps
     IOS9之后，苹果进一步完善了安全机制，必须在plist里面设置url scheme白名单，不然无法打开对应的应用.
     添加一个字段：LSApplicationQueriesSchemes，类型为数组，然后在这个数组里面再添加我们所需要的地图 URL Scheme :
     */

    // 1.先检测有没有对应的app，有的话再加入
    NSString *appName = [FATExtUtil getAppName];
    NSString *title = [NSString stringWithFormat:@"%@%@", [[FATClient sharedClient] fat_localizedStringForKey:@"Navigate to"], data[@"destination"]];
    CLLocationCoordinate2D coordinate = {[data[@"latitude"] doubleValue], [data[@"longitude"] doubleValue]};
    // 打开地图进行导航
    // 1.创建UIAlertController
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *appleAction = [UIAlertAction actionWithTitle:[[FATClient sharedClient] fat_localizedStringForKey:@"Apple Maps"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude);
        MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
        MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:loc addressDictionary:nil]];
        toLocation.name = data[@"destination"] ? data[@"destination"] : @"未知地点";
        [MKMapItem openMapsWithItems:@[ currentLocation, toLocation ]
                       launchOptions:@{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving,
                                       MKLaunchOptionsShowsTrafficKey : [NSNumber numberWithBool:YES]}];
    }];
    [appleAction setValue:[self labelColor] forKey:@"titleTextColor"];
    UIAlertAction *bdAction = [UIAlertAction actionWithTitle:[[FATClient sharedClient] fat_localizedStringForKey:@"Baidu Maps"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        NSString *urlString = [[NSString stringWithFormat:@"baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=目的地&mode=driving&coord_type=gcj02", coordinate.latitude, coordinate.longitude] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }];
    [bdAction setValue:[self labelColor] forKey:@"titleTextColor"];
    UIAlertAction *gdAction = [UIAlertAction actionWithTitle:[[FATClient sharedClient] fat_localizedStringForKey:@"Amap"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        NSString *urlString = [[NSString stringWithFormat:@"iosamap://path?sourceApplication=%@&backScheme=%@&dlat=%f&dlon=%f&dev=0&t=0&dname=%@", appName, @"iosamap://", coordinate.latitude, coordinate.longitude, data[@"destination"]] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }];
    [gdAction setValue:[self labelColor] forKey:@"titleTextColor"];
    UIAlertAction *googleAction = [UIAlertAction actionWithTitle:[[FATClient sharedClient] fat_localizedStringForKey:@"Google Maps"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        NSString *urlString = [[NSString stringWithFormat:@"comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%f,%f&directionsmode=driving", appName, @"comgooglemaps://", coordinate.latitude, coordinate.longitude] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }];
    [googleAction setValue:[self labelColor] forKey:@"titleTextColor"];
    UIAlertAction *tencentAction = [UIAlertAction actionWithTitle:[[FATClient sharedClient] fat_localizedStringForKey:@"Tencent Maps"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        NSString *urlString = [[NSString stringWithFormat:@"qqmap://map/routeplan?from=我的位置&type=drive&to=%@&tocoord=%f,%f&coord_type=1&referer={ios.blackfish.XHY}",data[@"destination"],coordinate.latitude,coordinate.longitude] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }];
    [tencentAction setValue:[self labelColor] forKey:@"titleTextColor"];

    NSString *cancel = [[FATClient sharedClient] fat_localizedStringForKey:@"Cancel"];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action){
        //        [alertController ]
    }];
    [cancelAction setValue:[self labelColor] forKey:@"titleTextColor"];
    // 1.先检测有没有对应的app，有的话再加入
    [alertController addAction:appleAction];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        [alertController addAction:bdAction];
    }
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        [alertController addAction:gdAction];
    }
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        [alertController addAction:googleAction];
    }
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"qqmap://"]]){
        [alertController addAction:tencentAction];
    }
    [alertController addAction:cancelAction];
    UIViewController *topVC = [[UIApplication sharedApplication] fat_topViewController];
    [topVC presentViewController:alertController animated:YES completion:nil];
}

- (UIColor *)labelColor {
    if (@available(iOS 12.0, *)) {
        BOOL isDark = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
        return isDark ? [UIColor colorWithRed:208/255.0 green:208/255.0 blue:208/255.0 alpha:1/1.0] :  [UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1/1.0];
    } else {
        return [UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1/1.0];
    }
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

@end
