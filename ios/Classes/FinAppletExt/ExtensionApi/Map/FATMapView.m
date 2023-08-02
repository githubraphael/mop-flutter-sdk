//
//  FATMapView.m
//  FBRetainCycleDetector
//
//  Created by 王兆耀 on 2021/9/1.
//

#import "FATMapView.h"
#import "MKMarkerView.h"
#import "FATExtHelper.h"
#import "FATExtUtil.h"
#import "FATWGS84ConvertToGCJ02.h"
#import "FATExtLocationManager.h"

#import <FinApplet/FinApplet.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface FATMapView ()<CLLocationManagerDelegate,MKMapViewDelegate>

@property (nonatomic, copy) NSString *pageId;
@property (nonatomic, strong) FATExtLocationManager *locationManager;
@property (nonatomic, assign) double Delta;
@property (nonatomic, strong) NSMutableDictionary *centerDic;
@property (nonatomic, strong) NSMutableArray<MKMarker *> *markerArray;
@property (nonatomic, assign) CGPoint centerOffset;
@property (nonatomic, assign) CLLocationCoordinate2D defaluStartCoordinate;
@property (nonatomic, assign) CLLocationCoordinate2D locationCoordinate;
@property (nonatomic, assign) double maxScale;
@property (nonatomic, assign) double minScale;
@property (nonatomic, assign) double settingScale;
@property (nonatomic, copy) NSDictionary *paramDic;// 记录初始化的参数
@property (nonatomic, strong) NSMutableArray *polylineArray;
@property (nonatomic, strong) NSMutableArray *circleArray;
@property (nonatomic, strong) NSMutableArray *polygonsArray;
@property (nonatomic, assign) NSUInteger polylineArrayCount;
@property (nonatomic, assign) NSUInteger circleArrayCount;
@property (nonatomic, assign) NSUInteger polygonsArrayCount;
@property (nonatomic, copy) NSString *markerIcon;
@property (nonatomic, assign) double latitudeAbnormal; // 记录纬度的异常值
@property (nonatomic, assign) double longitudeAbnormal;


@end

@implementation FATMapView


- (NSMutableArray *)markerArray {
    if (!_markerArray) {
        _markerArray = [[NSMutableArray alloc] init];
    }
    return _markerArray;
}

- (NSDictionary *)paramDic {
    if (!_paramDic) {
        _paramDic = [[NSDictionary alloc] init];
    }
    return _paramDic;
}

- (FATExtLocationManager *)locationManager
{
    if (_locationManager == nil) {
        _locationManager = [[FATExtLocationManager alloc]init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (instancetype)initWithParam:(NSDictionary *)param mapPageId:(NSString *)pageId {
    self = [super init];
    self.paramDic = param;
    NSDictionary *style = [param objectForKey:@"style"];
    if (style) {
        self.frame = [self getMapFrame:param];
    }
    self.delegate = self;
    self.pageId = pageId;
    self.maxScale = [param[@"maxScale"] doubleValue];
    self.minScale = [param[@"minScale"] doubleValue];
    self.showsCompass = NO;
    self.showsScale = NO;
    self.rotateEnabled = NO;
    self.zoomEnabled = YES;
    self.scrollEnabled  = YES;
    self.showsTraffic = NO;
    self.showsPointsOfInterest = YES;
    self.pitchEnabled = NO;
    [self updateMap:param];
    if (@available(iOS 11.0, *)) {
        [self registerClass:MKAnnotationView.class forAnnotationViewWithReuseIdentifier:@"markerView"];
    }
    return self;
}


- (void)updateWithParam:(NSDictionary *)param {
    NSDictionary *style = [param objectForKey:@"style"];
    if (style) {
        self.frame = [self getMapFrame:param];
    }
    [self updateMap:param];
}

- (CGRect)getMapFrame:(NSDictionary *)param {
    CGRect frame = CGRectZero;
    NSDictionary *style = [param objectForKey:@"style"];
    CGFloat x = [[style objectForKey:@"left"] floatValue];
    CGFloat y = [[style objectForKey:@"top"] floatValue];
    if ([self.paramDic.allKeys containsObject:@"cid"]) {
        x = 0.0;
        y= 0.0;
    }
    CGFloat height = [[style objectForKey:@"height"] floatValue];
    CGFloat width = [[style objectForKey:@"width"] floatValue];
    frame = CGRectMake(x, y, width, height);
    return frame;
}

- (void)updateMap:(NSDictionary *)param {
    NSDictionary *dic;
    NSDictionary *setting;
    if ([param objectForKey:@"setting"]) {
        setting = [[NSDictionary alloc] initWithDictionary:param[@"setting"]];
    }
    if (setting.allKeys.count > 0 ) {
        dic = param[@"setting"];
    } else {
        dic = param;
    }
    if (dic[@"showCompass"]) {
        if (@available(iOS 9.0, *)) {
            self.showsCompass = [dic[@"showCompass"] boolValue];
        } else {
            // Fallback on earlier versions
        }
    }
    if (dic[@"showScale"]) {
        if (@available(iOS 9.0, *)) {
            self.showsScale = [dic[@"showScale"] boolValue];
        } else {
            // Fallback on earlier versions
        }
    }
    if (dic[@"enableRotate"]) {// 设置地图可旋转
        self.rotateEnabled = [dic[@"enableRotate"] boolValue];
    }
    if (dic[@"showLocation"]) {//显示当前位置
        self.showsUserLocation = [dic[@"showLocation"] boolValue];
        if ([dic[@"showLocation"] boolValue]) {
            [self startStandardUpdates];
        }
    }
    if (dic[@"enable3D"]) {//是否显示3D
        self.pitchEnabled = [dic[@"enable3D"] boolValue];
    }
    if (dic[@"enableTraffic"]) {//是否显示实时路况
        if (@available(iOS 9.0, *)) {
            self.showsTraffic = [dic[@"enableTraffic"] boolValue];
        } else {
            // Fallback on earlier versions
        }
    }
    if (dic[@"enablePoi"]) {//是否显示POI
        self.showsPointsOfInterest = [dic[@"enablePoi"] boolValue];
    }
    if (dic[@"enableScroll"]) {
        self.scrollEnabled = [dic[@"enableScroll"] boolValue];
    }
    if (dic[@"enableBuilding"]) {
        self.showsBuildings = [dic[@"enableBuilding"] boolValue];
    }
    if (dic[@"enableSatellite"]) {
        self.mapType = [dic[@"enableSatellite"] boolValue] ? MKMapTypeSatellite : MKMapTypeStandard;
    }
    // 关闭暗黑模式
    //    if (@available(iOS 13.0, *)) {
    //        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    //    }
    if (param[@"polygons"]) {
        [self setpolygonView:param[@"polygons"]];
    }
    if (param[@"polyline"]) {
        [self setPolylineView:param[@"polyline"]];
    }
    if (param[@"circles"]) {
        [self setMKCircle:param[@"circles"]];
    }
    if (param[@"markers"]) {
        [self fat_removeAllMarker];
        [self fat_addMarkers:param isUpdateEvent:YES];
    }
    if (param[@"maxScale"]) {
        self.maxScale = [param[@"maxScale"] doubleValue];
        [self changeScale];
    }
    if (param[@"minScale"]) {
        self.minScale = [param[@"minScale"] doubleValue];
        [self changeScale];
    }
    if (dic[@"enableZoom"]) {// 设置地图可缩放
        self.zoomEnabled = [dic[@"enableZoom"] boolValue];
    }
 
    if (param[@"latitude"] && param[@"longitude"]) {
        CLLocationCoordinate2D centerCoord = { [self judgeLatition:[param[@"latitude"] doubleValue]], [self judgeLongitude:[param[@"longitude"] doubleValue]] };
        [self setRegion:MKCoordinateRegionMake(centerCoord, MKCoordinateSpanMake(self.Delta, self.Delta)) animated:YES];
        self.centerDic = [[NSMutableDictionary alloc] initWithDictionary:@{@"longitude":@([param[@"longitude"] doubleValue]), @"latitude":@([param[@"latitude"] doubleValue])}];
        self.longitudeAbnormal = [param[@"longitude"] doubleValue];
        self.latitudeAbnormal = [param[@"latitude"] doubleValue];
        
    }
    double latitude = [self judgeLatition:[self.centerDic[@"latitude"] doubleValue]];
    double longitude = [self judgeLongitude:[self.centerDic[@"longitude"] doubleValue]];
    
    if (param[@"latitude"] && !param[@"longitude"]) {
        double latitudes = [self judgeLatition:[param[@"latitude"] doubleValue]];
        self.latitudeAbnormal = latitudes;
        CLLocationCoordinate2D centerCoord = { latitudes, longitude };
        [self setRegion:MKCoordinateRegionMake(centerCoord, MKCoordinateSpanMake(self.Delta, self.Delta)) animated:YES];
    }
    if (param[@"longitude"] && !param[@"latitude"]) {
        double longitudes = [self judgeLongitude:[param[@"longitude"] doubleValue]];
        self.longitudeAbnormal = longitudes;
        CLLocationCoordinate2D centerCoord = { latitude, longitudes };
        [self setRegion:MKCoordinateRegionMake(centerCoord, MKCoordinateSpanMake(self.Delta, self.Delta)) animated:YES];
    }
    
    if (param[@"scale"]) {
        double scale = [param[@"scale"] doubleValue];
        if ([param[@"scale"] doubleValue] > self.maxScale) {
            scale = self.maxScale;
        }
        if ([param[@"scale"] doubleValue] < self.minScale) {
            scale = self.minScale;
        }
        double LongitudeDelta = [self fat_getLongitudeDelta:scale];
        self.Delta = LongitudeDelta;
        self.settingScale = scale;
        CLLocationCoordinate2D centerCoord = { latitude, longitude };
        [self setRegion:MKCoordinateRegionMake(centerCoord, MKCoordinateSpanMake(self.Delta, self.Delta)) animated:YES];
    }
    if (param[@"includePoints"]) {
        NSArray *arrary = [[NSArray alloc] initWithArray:param[@"includePoints"]];
        [self fat_includePoints:@{@"points":arrary}];
    }
}


- (void)startStandardUpdates{
    
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


- (void)setpolygonView:(NSArray *)data {

    data = [self checkArrayData:data];
    NSMutableArray *lineArray = [[NSMutableArray alloc] initWithArray:self.overlays];
    [lineArray enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([obj isKindOfClass:MKPolygon.class]) {
            [self removeOverlay:obj];
        }
    }];
    self.polygonsArrayCount = 0;
    self.polygonsArray = [[NSMutableArray alloc] initWithArray:data];
    for (NSDictionary *dic in data) {
        if ([dic[@"points"] isKindOfClass:NSArray.class]) {
            NSArray *polygonsArray = [[NSArray alloc] initWithArray:dic[@"points"]];
            CLLocationCoordinate2D points[polygonsArray.count + 1];
            
            for (int i = 0; i <polygonsArray.count; i++) {
                points[i] = CLLocationCoordinate2DMake([polygonsArray[i][@"latitude"] doubleValue], [polygonsArray[i][@"longitude"] doubleValue]);
            }
            MKPolygon *poly = [MKPolygon polygonWithCoordinates:points count:polygonsArray.count];
            [self addOverlay:poly];
            self.polygonsArrayCount++;
        }
    }
}

- (void)setPolylineView:(NSArray *)data {

    data = [self checkArrayData:data];

    NSMutableArray *lineArray = [[NSMutableArray alloc] initWithArray:self.overlays];
    [lineArray enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([obj isKindOfClass:MKPolyline.class]) {
            [self removeOverlay:obj];
        }
    }];
    self.polylineArrayCount = 0;
    NSMutableSet *setOne = [NSMutableSet setWithArray:data];
    NSMutableSet *setTwo = [NSMutableSet setWithArray:self.polylineArray];
    self.polylineArray = [[NSMutableArray alloc] initWithArray:data];
    [setOne minusSet:setTwo];
    NSArray *resultAry = [setOne allObjects];
    for (NSDictionary *dic in resultAry) {
        if ([dic[@"points"] isKindOfClass:NSArray.class]) {
            NSArray *polygonsArray = [[NSArray alloc] initWithArray:dic[@"points"]];
            CLLocationCoordinate2D points[polygonsArray.count + 1];
            
            for (int i = 0; i <polygonsArray.count; i++) {
                points[i] = CLLocationCoordinate2DMake([polygonsArray[i][@"latitude"] doubleValue], [polygonsArray[i][@"longitude"] doubleValue]);
            }
            MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:points count:polygonsArray.count];
            self.polylineArrayCount = [self.polylineArray indexOfObject:dic];
            [self addOverlay:polyLine];
        }
    }
}

- (void)setMKCircle:(NSArray *)data {
    data = [self checkArrayData:data];
    NSMutableArray *lineArray = [[NSMutableArray alloc] initWithArray:self.overlays];
    [lineArray enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([obj isKindOfClass:MKCircle.class]) {
            [self removeOverlay:obj];
        }
    }];
    self.circleArrayCount = 0;
    self.circleArray = [[NSMutableArray alloc] initWithArray:data];
    for (NSDictionary *dic in data) {
        MKCircle *circleTargePlace=[MKCircle circleWithCenterCoordinate:CLLocationCoordinate2DMake([dic[@"latitude"] doubleValue], [dic[@"longitude"] doubleValue]) radius:[dic[@"radius"] doubleValue]];
        [self addOverlay:circleTargePlace];
        self.circleArrayCount++;
    }
    
}


#pragma mark --- 方法实现
- (NSDictionary *)fat_getCenter {
    return self.centerDic;
}

/// 获取当前地图的倾斜角
- (NSDictionary *)fat_getskew {
    
    CGPoint southWestPoint = CGPointMake(self.frame.origin.x, self.frame.size.height);
    // 将屏幕坐标转换为经纬度
    CLLocationCoordinate2D southWestCpprdonate = [self convertPoint:southWestPoint toCoordinateFromView:self];
    
    double angle = [self getBearingWithLat1:self.defaluStartCoordinate.latitude whitLng1:self.defaluStartCoordinate.longitude whitLat2:southWestCpprdonate.latitude whitLng2:southWestCpprdonate.longitude];
    
    if (angle < 0) {
        angle = -angle  + 180;
    }
    if isnan(angle) {
        angle = 0;
    }
    
    return @{@"skew":@(angle)};
}

// 计算当前的缩放级别。
- (double)fat_getScale {
    double scale = log2(360 * self.frame.size.width / 256.0 / self.region.span.latitudeDelta);
    
    return self.settingScale <= 3 ? 3.00 : scale;
}

// 计算当前MKMapView显示区域的经度范围。
- (double)fat_getLongitudeDelta:(double) scale {
    
    double longitudeDelta = (360 * self.frame.size.width / 256.0 / pow(2, scale));
    return longitudeDelta;
}

- (NSString *)fat_moveToLocation:(NSDictionary *)data {
    
    if (![data[@"latitude"] doubleValue] && [data[@"longitude"] doubleValue]) {
        CLLocationCoordinate2D centerCoord = { 0.00, [self judgeLongitude:[data[@"longitude"] doubleValue]] };
        self.centerDic = [[NSMutableDictionary alloc] initWithDictionary:@{@"longitude":@(centerCoord.longitude), @"latitude":@(0)}];
        self.latitudeAbnormal = 0;
        [self setRegion:MKCoordinateRegionMake(centerCoord, MKCoordinateSpanMake(self.Delta, self.Delta)) animated:YES];
        return @"success";
    }
    if (![data[@"longitude"] doubleValue] && [data[@"latitude"] doubleValue]) {
        CLLocationCoordinate2D centerCoord = { [self judgeLatition:[data[@"latitude"] doubleValue]], 0.00 };
        self.centerDic = [[NSMutableDictionary alloc] initWithDictionary:@{@"longitude":@(0), @"latitude":@(centerCoord.latitude)}];
        self.longitudeAbnormal = 0;
        [self setRegion:MKCoordinateRegionMake(centerCoord, MKCoordinateSpanMake(self.Delta, self.Delta)) animated:YES];
        return @"success";
    }
    if (![data[@"latitude"] doubleValue] && ![data[@"longitude"] doubleValue]) {
        if (self.showsUserLocation) {
            [self setCenterCoordinate:self.locationCoordinate];
            return @"success";
        }
        return @"fail";
    }
    CLLocationCoordinate2D centerCoord = { [self judgeLatition:[data[@"latitude"] doubleValue]], [self judgeLongitude:[data[@"longitude"] doubleValue]] };
    self.centerDic = [[NSMutableDictionary alloc] initWithDictionary:@{@"longitude":@(centerCoord.longitude), @"latitude":@(centerCoord.latitude)}];
    self.longitudeAbnormal = centerCoord.longitude;
    self.latitudeAbnormal = centerCoord.latitude;
    [self setRegion:MKCoordinateRegionMake(centerCoord, MKCoordinateSpanMake(self.Delta, self.Delta)) animated:YES];
    return @"success";
}

- (void)fat_includePoints:(NSDictionary *)data {
    
    NSArray *imageDataArr = [[NSArray alloc] initWithArray:data[@"points"]];
    imageDataArr = [self checkArrayData:imageDataArr];
    double _minLat = 0.0;
    double _maxLat = 0.0;
    double _minLon = 0.0;
    double _maxLon = 0.0;
    
    for (NSInteger i = 0; i < imageDataArr.count; i++) {
        if (i==0) {
            //以第一个坐标点做初始值
            _minLat = [imageDataArr[i][@"latitude"] doubleValue];
            _maxLat = [imageDataArr[i][@"latitude"] doubleValue];
            _minLon = [imageDataArr[i][@"longitude"] doubleValue];
            _maxLon = [imageDataArr[i][@"longitude"] doubleValue];
        }else{
            //对比筛选出最小纬度，最大纬度；最小经度，最大经度
            _minLat = MIN(_minLat, [imageDataArr[i][@"latitude"] doubleValue]);
            _maxLat = MAX(_maxLat, [imageDataArr[i][@"latitude"] doubleValue]);
            _minLon = MIN(_minLon, [imageDataArr[i][@"longitude"] doubleValue]);
            _maxLon = MAX(_maxLon, [imageDataArr[i][@"longitude"] doubleValue]);
        }
        //动态的根据坐标数据的区域，来确定地图的显示中心点和缩放级别
        if (imageDataArr.count > 0) {
            //计算中心点
            CLLocationCoordinate2D centCoor;
            centCoor.latitude = (CLLocationDegrees)((_maxLat+_minLat) * 0.5f);
            centCoor.longitude = (CLLocationDegrees)((_maxLon+_minLon) * 0.5f);
            MKCoordinateSpan span;
            //计算地理位置的跨度
            span.latitudeDelta = _maxLat - _minLat;
            span.longitudeDelta = _maxLon - _minLon;
            //得出数据的坐标区域
            MKCoordinateRegion region = MKCoordinateRegionMake(centCoor, span);
            [self setRegion:region];
            self.latitudeAbnormal = region.center.latitude;
            self.longitudeAbnormal = region.center.longitude;
        }
    }
}

- (NSDictionary *)fat_mapgetRegion {
    CGPoint southWestPoint = CGPointMake(self.frame.origin.x, self.frame.size.height);
    CGPoint northEastPoint = CGPointMake(self.frame.size.width, self.frame.origin.x);
    // 将屏幕坐标转换为经纬度
    CLLocationCoordinate2D southWestCpprdonate = [self convertPoint:southWestPoint toCoordinateFromView:self];
    CLLocationCoordinate2D northEastCpprdonate = [self convertPoint:northEastPoint toCoordinateFromView:self];
    //    NSLog(@"西南角经纬度=%@，东北角经纬度=%@",southWestCpprdonate,northEastCpprdonate);
    NSDictionary *dic = @{@"southwest":@{@"longitude":@(southWestCpprdonate.longitude),
                                         @"latitude":@(southWestCpprdonate.latitude)},
                          @"northeast":@{@"longitude":@(northEastCpprdonate.longitude),
                                         @"latitude":@(northEastCpprdonate.latitude)}
    };
    return dic;
}

- (NSDictionary *)fat_fromScreenLocation {
    CGPoint startingCpprdonatePoint = CGPointMake(self.frame.origin.x, self.frame.origin.x);
    // 将屏幕坐标转换为经纬度
    CLLocationCoordinate2D startingCpprdonate = [self convertPoint:startingCpprdonatePoint toCoordinateFromView:self];
    //    NSLog(@"西南角经纬度=%@，东北角经纬度=%@",southWestCpprdonate,northEastCpprdonate);
    NSDictionary *dic = @{@"longitude":@(startingCpprdonate.longitude),
                          @"latitude":@(startingCpprdonate.latitude)};
    return dic;
}

- (CGPoint)fat_toScreenLocation:(NSDictionary *)data {
    CLLocationCoordinate2D centerCoord = { [data[@"latitude"] doubleValue], [data[@"longitude"] doubleValue] };
    CGPoint point = [self convertCoordinate:centerCoord toPointToView:self];
    return point;
}

- (void)fat_openMapApp:(NSDictionary *)data {

    NSString *appName = [FATExtUtil getAppName];
    NSString *title = [NSString stringWithFormat:@"%@%@", [[FATClient sharedClient] fat_localizedStringForKey:@"Navigate to"], data[@"destination"]];
    CLLocationCoordinate2D coordinate = {[data[@"latitude"] doubleValue], [data[@"longitude"] doubleValue]};
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *appleAction = [UIAlertAction actionWithTitle:[[FATClient sharedClient] fat_localizedStringForKey:@"Apple Maps"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude);
        MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
        MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:loc addressDictionary:nil]];
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

- (void)fat_addMarkers:(NSDictionary *)data {
    [self fat_addMarkers:data isUpdateEvent:NO];
}

// 如果是update事件里调用的话，参数为空需要移除
- (void)fat_addMarkers:(NSDictionary *)data isUpdateEvent:(BOOL)isUpdate {
    NSArray *markerArray = data[@"markers"];
    if (isUpdate && markerArray.count == 0) {
        [self fat_removeAllMarker];
        return;
    }
    if (data[@"clear"] && [data[@"clear"] boolValue]) {
        [self fat_removeAllMarker];
    }
    // 添加大头针
    [self addMarker:markerArray];
}

-(void)fat_removeAllMarker {
    [self.markerArray removeAllObjects];
    NSArray *array = self.annotations;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeAnnotations:array];
    });
}

- (void)addMarker:(NSArray *)array {
    for (NSDictionary *dic in array) {
        CLLocationCoordinate2D centerCoord = { [dic[@"latitude"] doubleValue], [dic[@"longitude"] doubleValue] };
        MKMarker *marker =  [[MKMarker alloc] init];
        marker.idString = [NSString stringWithFormat:@"%@", dic[@"id"]];
        if (dic[@"iconPath"]) {
            NSString *filePath;
            if (![dic[@"iconPath"] containsString:@"http"]) {
                filePath= [[FATClient sharedClient] getFileAddressWithfileName:dic[@"iconPath"]];
            } else {
                filePath = dic[@"iconPath"];
            }
            marker.image = [UIImage fat_getImageWithUrl:filePath];
        } else {
            marker.image = [FATExtHelper fat_ext_imageFromBundleWithName:@"fav_fileicon_loc90"];
        }
        marker.coordinate = centerCoord;
        [self.markerArray addObject:marker];
        marker.title = dic[@"label"][@"content"];
        marker.subtitle = dic[@"callout"][@"content"];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self addAnnotations:self.markerArray];
    });
}

- (void)fat_removeMarkers:(NSDictionary *)data {
    if ([data.allKeys containsObject:@"markerIds"]) {
        NSArray *dataArray = [[NSArray alloc] initWithArray:data[@"markerIds"]];
        NSMutableArray *deleteArray = [[NSMutableArray alloc] init];
        [dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *idNumber = [NSString stringWithFormat:@"%@",obj];
            for (MKMarker *marker in self.markerArray) {
                if (idNumber == marker.idString) {
                    [deleteArray addObject:marker];
                }
            }
        }];
        
        [deleteArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            MKMarker *marker = obj;
            [self.markerArray removeObject:marker];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeAnnotations:deleteArray];
        });
    }
}

- (BOOL)fat_translateMarker:(NSDictionary *)data {
    NSString *idNumber = [NSString stringWithFormat:@"%@",data[@"markerId"]];
    BOOL markerIdIsExit = NO;
    for (MKMarker *marker in self.markerArray) {
        if (idNumber == marker.idString) {
            markerIdIsExit = YES;
            CLLocationCoordinate2D centerCoord = { [data[@"destination"][@"latitude"] doubleValue], [data[@"destination"][@"longitude"] doubleValue] };
            NSInteger duration = ([data[@"duration"] integerValue] ? [data[@"duration"] integerValue] : 1000) / 1000;
            // 1.把坐标点转化为frame
            NSValue *value2 = [NSValue valueWithMKCoordinate:centerCoord];
            __block NSArray *array = @[value2];
            [self newStartMoving:marker pointArray:array duration:duration];
        }
    }
    return markerIdIsExit;
    
}

- (void)newStartMoving:(MKMarker *)marker pointArray:(NSArray *)array duration:(NSInteger)duration {
    
    __block NSInteger number = 0;
    
    [UIView animateWithDuration:duration animations:^{
        NSValue *value = array[number];
        CLLocationCoordinate2D coord = [value MKCoordinateValue];
        marker.coordinate = coord;
        number++;
    } completion:^(BOOL finished) {
        if (index < array.count-1) {
            [self newStartMoving:marker pointArray:array duration:duration];
        }
    }];
}

- (BOOL)fat_moveAlong:(NSDictionary *)data {
    [self.layer removeAllAnimations];
    NSArray *pathArray = [[NSArray alloc] initWithArray:data[@"path"]];
    if (pathArray.count == 0 || ![pathArray isKindOfClass:[NSArray class]]) {
        return NO;
    }
    NSString *idNumber = [NSString stringWithFormat:@"%@", data[@"markerId"]];
    NSInteger duration = ([data[@"duration"] integerValue] ? [data[@"duration"] integerValue] : 1000) / 1000;
    BOOL markerIdIsExit = NO;
    for (MKMarker *marker in self.markerArray) {
        if (idNumber == marker.idString) {
            markerIdIsExit = YES;
            [self moveAlong:marker pathArray:pathArray duration:duration Count:0];
        }
    }
    return markerIdIsExit;
}

- (void)moveAlong:(MKMarker *)marker pathArray:(NSArray *)array duration:(NSInteger)duration Count:(NSInteger)count {
    __weak typeof(self) weakSelf = self;
    CGFloat time =(CGFloat) duration/array.count;
    [UIView animateWithDuration:time animations:^{
        NSDictionary *dic = array[count];
        CLLocationCoordinate2D centerCoord = {[dic[@"latitude"] doubleValue], [dic[@"longitude"] doubleValue]};
        CLLocationCoordinate2D coord = centerCoord;
        marker.coordinate = coord;
    } completion:^(BOOL finished) {
        if (count < array.count - 1) {
//            __weak id weakSelf = self;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [weakSelf moveAlong:marker pathArray:array duration:duration Count:count + 1];
            }];
        }
    }];
}

#pragma mark - MKMapViewDelegate
- (nullable MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation{
    
    // If the annotation is the user location, just return nil.（如果是显示用户位置的Annotation,则使用默认的蓝色圆点）
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    if ([annotation isKindOfClass:MKMarker.class]) {
        MKMarker *marker = (MKMarker *)annotation;
        MKAnnotationView *markerView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"markerView"];
        markerView.canShowCallout = YES;
        markerView.annotation = marker;
        if (self.markerIcon) {
            markerView.image = [UIImage fat_getImageWithUrl:self.markerIcon];
        } else {
            markerView.image = marker.image;
        }
        markerView.centerOffset = CGPointMake(0, -12.5);
        return markerView;
    }
    return nil;
}
/// 气泡的点击事件
-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    if ([view.annotation isKindOfClass:MKMarker.class]) {
        MKMarker *marker = (MKMarker *)view.annotation;
        NSDictionary *dic = @{@"mapId":self.paramDic[@"mapId"],
                              @"pageId":self.pageId,
                              @"eventName":@"markertap",
                              @"detail":@{@"markerId":marker.idString}
        };        
        if (self.eventCallBack) {
            self.eventCallBack(@"custom_event_onMapTask",dic);
        }
    }
}

/// 气泡的点击事件
-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views{
    for (MKAnnotationView *annotationView in views) {
        [mapView deselectAnnotation:annotationView.annotation animated:YES];
    }
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
    if (self.defaluStartCoordinate.latitude > 0) {
        return;
    }
    CGPoint southWestPoint = CGPointMake(self.frame.origin.x, self.frame.size.height);
    // 将屏幕坐标转换为经纬度
    CLLocationCoordinate2D southWestCpprdonate = [self convertPoint:southWestPoint toCoordinateFromView:self];
    self.defaluStartCoordinate = southWestCpprdonate;
    NSDictionary *dic = @{@"mapId":self.paramDic[@"mapId"],
                          @"pageId":self.pageId,
                          @"eventName":@"updated",
                          @"detail":@{}
    };
    if (self.eventCallBack) {
        self.eventCallBack(@"custom_event_onMapTask",dic);
    }
    
//    FATAppletInfo *appInfo = [[FATClient sharedClient] currentApplet];
//    [[FATExtCoreEventManager shareInstance] sendComponentWithAppId:appInfo.appId eventName:@"custom_event_onMapTask" paramDict:dic];
//
}

//当拖拽，放大，缩小，双击手势开始时调用
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    
    NSDictionary *skew = [self fat_getskew];
    double scale = log2(360 * self.frame.size.width / 256.0 / self.region.span.latitudeDelta);
    NSDictionary *regionDic = [self fat_mapgetRegion];
    if (!self.centerDic) {
        self.centerDic = [[NSMutableDictionary alloc] initWithDictionary:@{@"0":@"0"}];
    }
    NSDictionary *dic = @{@"mapId":self.paramDic[@"mapId"],
                          @"pageId":self.pageId,
                          @"eventName":@"regionchange",
                          @"type":@"begin",
                          @"detail":@{@"rotate":@"",
                                      @"skew":skew[@"skew"],
                                      @"scale":[NSString stringWithFormat:@"%f", scale],
                                      @"centerLocation":self.centerDic,
                                      @"region":regionDic
                          }
    };
    
    if (self.eventCallBack) {
        self.eventCallBack(@"custom_event_onMapTask",dic);
    }
    
//    FATAppletInfo *appInfo = [[FATClient sharedClient] currentApplet];
//    [[FATExtCoreEventManager shareInstance] sendComponentWithAppId:appInfo.appId eventName:@"custom_event_onMapTask" paramDict:dic];
}


#pragma mark-CLLocationManagerDelegate

// 获取到的地图中心点坐标，传递给基础库
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    MKCoordinateRegion region;
    CLLocationCoordinate2D centerCoordinate = mapView.region.center;
    region.center = mapView.region.center;
    //判断是不是属于国内范围
    if (![FATWGS84ConvertToGCJ02ForAMapView isLocationOutOfChina:centerCoordinate]) {
        //转换后的coord
        CLLocationCoordinate2D coord = [FATWGS84ConvertToGCJ02ForAMapView transformFromWGSToGCJ:centerCoordinate];
        region.center = coord;
    }
    
    if (self.latitudeAbnormal == 0 || self.latitudeAbnormal == 85 || self.latitudeAbnormal == -85) {
        [self.centerDic setValue:@(self.latitudeAbnormal) forKey:@"latitude"];
    } else {
        [self.centerDic setValue:@(region.center.latitude) forKey:@"latitude"];
    }
    if (self.longitudeAbnormal == 0 || self.longitudeAbnormal == 180 || self.longitudeAbnormal == -180) {
        [self.centerDic setValue:@(self.longitudeAbnormal) forKey:@"longitude"];
    } else {
        [self.centerDic setValue:@(region.center.longitude) forKey:@"longitude"];
    }
    //    self.centerDic = @{@"longitude":@(region.center.longitude),@"latitude":@(region.center.latitude)};
    
    NSDictionary *skew = [self fat_getskew];
    double scale = log2(360 * self.frame.size.width / 256.0 / self.region.span.latitudeDelta);
    NSDictionary *regionDic = [self fat_mapgetRegion];
    if (!self.centerDic) {
        self.centerDic = [[NSMutableDictionary alloc] initWithDictionary:@{@"0":@"0"}];
    }
    NSDictionary *dic = @{@"mapId":self.paramDic[@"mapId"],
                          @"eventName":@"regionchange",
                          @"pageId":self.pageId,
                          @"type" : @"end",
                          @"detail":@{@"rotate":@"",
                                      @"skew":skew[@"skew"],
                                      @"scale":[NSString stringWithFormat:@"%f", scale],
                                      @"centerLocation":self.centerDic,
                                      @"region":regionDic
                          }
    };
    
    if (self.eventCallBack) {
        self.eventCallBack(@"custom_event_onMapTask",dic);
    }
    
//    FATAppletInfo *appInfo = [[FATClient sharedClient] currentApplet];
//    [[FATExtCoreEventManager shareInstance] sendComponentWithAppId:appInfo.appId eventName:@"custom_event_onMapTask" paramDict:dic];
}

/**
 *  更新到位置之后调用
 *
 *  @param manager   位置管理者
 *  @param locations 位置数组
 */
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:( NSArray *)locations
{
    CLLocation *location = [locations firstObject];
    //位置更新后的经纬度
    CLLocationCoordinate2D theCoordinate =  location.coordinate;
    self.locationCoordinate = theCoordinate;
    //设置地图显示的中心及范围
    //    MKCoordinateRegion theRegion;
    //    theRegion.center = theCoordinate;
    //    NSLog(@" 经纬度 %f,%f",theCoordinate.latitude, theCoordinate.longitude);
    //    CLLocationCoordinate2D centerCoord = { theCoordinate.latitude, theCoordinate.longitude };
    //    [self setRegion:MKCoordinateRegionMake(centerCoord, MKCoordinateSpanMake(self.Delta, self.Delta)) animated:YES];
    [self.locationManager stopUpdatingLocation];
}

/// 在地图上绘制对应的多边形，圆形，和路线
- (MKOverlayView*)mapView:(MKMapView*)mapView viewForOverlay:(id)overlay {
    if([overlay isKindOfClass:[MKPolygon class]]) {
        NSMutableArray *array = self.polygonsArray;
        NSDictionary *dic;
        if (array.count > self.polygonsArrayCount) {
            dic = array[self.polygonsArrayCount];
        } else {
            dic = [array lastObject];
        }
        MKPolygonView *polygonview = [[MKPolygonView alloc]initWithPolygon:(MKPolygon*)overlay];
        polygonview.fillColor = [UIColor fat_colorWithARGBHexString:dic[@"fillColor"]];
        polygonview.strokeColor = [UIColor fat_colorWithARGBHexString:dic[@"strokeColor"]];
        polygonview.lineWidth = [dic[@"strokeWidth"] floatValue];
        return polygonview;
    } else if ([overlay isKindOfClass:[MKPolyline class]]) {
        NSMutableArray *array = self.polylineArray;
        NSDictionary *dic;
        if (array.count > self.polylineArrayCount) {
            dic = array[self.polylineArrayCount];
        } else {
            dic = [array lastObject];
        }
        MKPolylineView *lineview = [[MKPolylineView alloc]initWithOverlay:(MKPolyline*)overlay];
        lineview.lineCap = kCGLineCapRound;
        lineview.strokeColor = [UIColor fat_colorWithARGBHexString:dic[@"color"] defaultHexString:@"#000000"];
        lineview.fillColor = [UIColor fat_colorWithARGBHexString:dic[@"borderColor"]];
        lineview.lineWidth = [dic[@"strokeWidth"] floatValue];
        lineview.layer.shouldRasterize = YES;
        return lineview;
    } else if ([overlay isKindOfClass:[MKCircle class]]) {
        NSMutableArray *array = self.circleArray;
        NSDictionary *dic;
        if (array.count > self.circleArrayCount) {
            dic = array[self.circleArrayCount];
        } else {
            dic = [array lastObject];
        }
        
        MKCircleView *corcleView = [[MKCircleView alloc] initWithCircle:overlay] ;
        corcleView.fillColor =  [UIColor fat_colorWithARGBHexString:dic[@"fillColor"]];
        corcleView.strokeColor = [UIColor fat_colorWithARGBHexString:dic[@"color"]];
        corcleView.lineWidth = [dic[@"strokeWidth"] floatValue];
        return corcleView;
    }
    return [MKOverlayView new];
}


#pragma mark -- CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    if (newHeading.headingAccuracy < 0)  return;
    
//    CLLocationDirection heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading;
//    CGFloat rotation =  heading/180 * M_PI;
    //    self.arrowImageView.transform = CGAffineTransformMakeRotation(rotation);
}

//- (void)tapPress:(UIGestureRecognizer *)gestureRecognizer {
//
//    CGPoint touchPoint = [gestureRecognizer locationInView:self ];
//    CLLocationCoordinate2D touchMapCoordinate =
//    [self convertPoint:touchPoint toCoordinateFromView:self];
//    //点击位置的经纬度
//    NSLog(@"%f %f",touchMapCoordinate.latitude, touchMapCoordinate.longitude);
//    NSDictionary *dic = @{@"mapId":self.paramDic[@"mapId"],
//                          @"eventName":@"tap",
//                          @"detail":@{@"latitude":@(touchMapCoordinate.latitude),
//                                      @"longitude":@(touchMapCoordinate.longitude)
//                          }
//    };
//    FATAppletInfo *appInfo = [[FATClient sharedClient] currentApplet];
//    [[FATExtCoreEventManager shareInstance] sendComponentWithAppId:appInfo.appId eventName:@"custom_event_onMapTask" paramDict:dic];
//}


#pragma mark -- tools method

- (NSArray *)checkArrayData:(NSArray *)array {
    // 清除数组中的异常数据
    NSMutableArray *dataArray = [[NSMutableArray alloc] initWithArray:array];
    [dataArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[NSDictionary class]]) {
            [dataArray removeObject:obj];
        }
    }];
    return dataArray;
}

- (void)changeScale {
    if (self.maxScale == self.minScale) {
        self.zoomEnabled = NO;
    } else {
        if (self.paramDic[@"enableZoom"]) {// 设置地图可缩放
            self.zoomEnabled = [self.paramDic[@"enableZoom"] boolValue];
        }
    }
}

//两个经纬度之间的角度
-(double)getBearingWithLat1:(double)lat1 whitLng1:(double)lng1 whitLat2:(double)lat2 whitLng2:(double)lng2{
    
    double d = 0;
    double radLat1 =  [self radian:lat1];
    double radLat2 =  [self radian:lat2];
    double radLng1 = [self radian:lng1];
    double radLng2 =  [self radian:lng2];
    d = sin(radLat1)*sin(radLat2)+cos(radLat1)*cos(radLat2)*cos(radLng2-radLng1);
    d = sqrt(1-d*d);
    d = cos(radLat2)*sin(radLng2-radLng1)/d;
    d = [self angle:asin(d)];
    return d;
}
//根据角度计算弧度
-(double)radian:(double)d {
    
    return d * M_PI/180.0;
}
//根据弧度计算角度
-(double)angle:(double)r {
    
    return r * 180/M_PI;
}
// 校验经度是否合规
-(double)judgeLatition:(double)latitude {
    if (latitude >= 90) {
        latitude = 85.00;
    }
    if (latitude <= -90) {
        latitude = -85.00;
    }
    return latitude;
}
// 校验纬度是否合规
-(double)judgeLongitude:(double)longitude {
    if (longitude >= 180) {
        longitude = 180.00;
    }
    if (longitude <= -180) {
        longitude = -180.00;
    }
    return longitude;
}


- (UIColor *)labelColor {
    if (@available(iOS 12.0, *)) {
        BOOL isDark = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
        return isDark ? [UIColor colorWithRed:208/255.0 green:208/255.0 blue:208/255.0 alpha:1/1.0] :  [UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1/1.0];
    } else {
        return [UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1/1.0];
    }
}

@end
