//
//  FATExtChoosePoiViewController.m
//  FinAppletExt
//
//  Created by 王兆耀 on 2021/12/8.
//

#import "FATExtChoosePoiViewController.h"
#import "FATLocationResultViewController.h"
#import "FATAnnotation.h"
#import "FATExtHelper.h"
#import "FATExtLocationManager.h"
#import "FATExtMapManager.h"
#import "FATExtUtil.h"

#import <CoreLocation/CoreLocation.h>

static NSString *kAnnotationId = @"FATAnnotationViewId";
static NSString *kUserAnnotationId = @"FATUserAnnotationViewId";

@interface FATExtChoosePoiViewController () <UITableViewDelegate, UITableViewDataSource, FATLocationResultDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) UIImageView *centerLocationView;
@property (nonatomic, strong) MKUserLocation *userLocation;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) FATLocationResultViewController *locationResultVC;
@property (nonatomic, strong) FATExtLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, copy) NSString *cityName;
@end

@implementation FATExtChoosePoiViewController

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc] init];
    }
    return _dataArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self p_initNavigationBar];
    
    [self p_initSubViews];
    
    [self startLocation];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    CGFloat searchBarH = self.searchController.searchBar.bounds.size.height;
    
    CGFloat totalH = height - searchBarH;
    
    self.centerLocationView.center = CGPointMake(width * 0.5, totalH * 0.5 * 0.5);
    
    self.tableView.frame = CGRectMake(0, 0, width, height);
    
    self.indicatorView.center = CGPointMake(width * 0.5, height * 0.5);
}

- (void)dealloc {
    _searchController = nil;
    _locationResultVC = nil;
}

#pragma mark - private method
- (void)p_initNavigationBar {
    self.title = [[FATClient sharedClient] fat_localizedStringForKey:@"Location"];
    
    NSString *cancel = [[FATClient sharedClient] fat_localizedStringForKey:@"Cancel"];
    NSString *ok = [[FATClient sharedClient] fat_localizedStringForKey:@"OK"];
    UIButton *cancelButton = [[UIButton alloc] init];
    [cancelButton setTitle:cancel forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelItemClick) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *okButton = [[UIButton alloc] init];
    [okButton setTitle:ok forState:UIControlStateNormal];
    [okButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [okButton addTarget:self action:@selector(sureItemClick) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:okButton];
}

- (void)p_initSubViews {
    [self p_initSearchBar];
    
    self.centerLocationView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    self.centerLocationView.image = [FATExtHelper fat_ext_imageFromBundleWithName:@"fav_fileicon_loc90"];
    
    [self.view addSubview:self.tableView];
    
    [self.view addSubview:self.indicatorView];
    [self.indicatorView startAnimating];
}

//开始定位
- (void)startLocation {
    //        CLog(@"--------开始定位");
    self.locationManager = [[FATExtLocationManager alloc] init];
    self.locationManager.delegate = self;
    // 控制定位精度,越高耗电量越
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    
    [self.locationManager requestWhenInUseAuthorization];
    self.locationManager.distanceFilter = 10.0f;
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if ([error code] == kCLErrorDenied) {
        //        NSLog(@"访问被拒绝");
    }
    if ([error code] == kCLErrorLocationUnknown) {
        //        NSLog(@"无法获取位置信息");
    }
}
//定位代理经纬度回调
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *newLocation = locations[0];
    
    CLLocationCoordinate2D centerCoordinate = newLocation.coordinate;
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *array, NSError *error) {
        CLPlacemark *placemark = nil;
        if (!error) {
            placemark = [array firstObject];
        }
        // 获取当前城市名
        NSString *city = placemark.locality;
        if (!city) {
            city = placemark.administrativeArea;
        }
        self.cityName = city;
        MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(centerCoordinate, 1000, 1000);
        request.region = region;
        request.naturalLanguageQuery = [[FATClient sharedClient] fat_localizedStringForKey:@"Office Building"];
        
        MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:request];
        if([FATExtMapManager shareInstance].googleMapApiKey.length > 1){
            [FATExtUtil getNearbyPlacesByCategory:request.naturalLanguageQuery coordinates: region.center radius:1000 token:@""
                                                   completion:^(NSDictionary * _Nonnull dict) {
                
                self.dataArray = [[NSMutableArray alloc] initWithArray: [FATExtUtil convertPlaceDictToArray:dict]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.indicatorView stopAnimating];
                    [self addSpecialCity];
                    [self.tableView reloadData];
                });
            }];
        }else {
            [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *_Nullable response, NSError *_Nullable error) {
                //NSMutableArray *placeArrayM = [NSMutableArray array];
//                if (placemark) {
//                    FATMapPlace *place = [[FATMapPlace alloc] init];
//                    place.name = placemark.name;
//                    place.address = placemark.thoroughfare;
//                    place.location = placemark.location;
//                    place.selected = YES;
//                    [self.dataArray addObject:place];
//                }
                for (MKMapItem *item in response.mapItems) {
                    if (!item.isCurrentLocation) {
                        FATMapPlace *place = [[FATMapPlace alloc] init];
                        place.name = item.placemark.name;
                        place.address = item.placemark.thoroughfare;
                        place.location = item.placemark.location;
                        [self.dataArray addObject:place];
                    }
                }
                [self.indicatorView stopAnimating];
                [self addSpecialCity];
                [self.tableView reloadData];
            }];
        }
    }];
    [manager stopUpdatingLocation];
}

- (void)p_initSearchBar {
    _locationResultVC = [FATLocationResultViewController new];
    _locationResultVC.delegate = self;
    _locationResultVC.searchBarHeight = self.searchController.searchBar.bounds.size.height;
    _searchController = [[UISearchController alloc] initWithSearchResultsController:_locationResultVC];
    _searchController.searchResultsUpdater = _locationResultVC;
    
    NSString *placeholder = [[FATClient sharedClient] fat_localizedStringForKey:@"Search nearby"];
    _searchController.searchBar.placeholder = placeholder;
    _searchController.searchBar.backgroundColor = [UIColor colorWithRed:239 / 255.0 green:239 / 255.0 blue:244 / 255.0 alpha:1];
    UITextField *searchField;
    if (@available(iOS 13.0, *)) {
        searchField = _searchController.searchBar.searchTextField;
    } else {
        searchField = [_searchController.searchBar valueForKey:@"searchField"];
    }
    searchField.layer.borderColor = [UIColor colorWithRed:218 / 255.0 green:219 / 255.0 blue:233 / 255.0 alpha:1].CGColor;
    self.tableView.tableHeaderView = _searchController.searchBar;
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
    FATMapPlace *selectPlace = nil;
    for (FATMapPlace *place in self.dataArray) {
        if (place.selected) {
            selectPlace = place;
            break;
        }
    }
    NSString *type;
    CLLocationCoordinate2D coordinate = selectPlace.location.coordinate;
    NSMutableDictionary *locationInfo = [[NSMutableDictionary alloc] initWithDictionary:@{@"latitude" : [NSString stringWithFormat:@"%@", @(coordinate.latitude)],
                                                                                          @"longitude" : [NSString stringWithFormat:@"%@", @(coordinate.longitude)]}];
    if ([selectPlace.name isEqualToString:[[FATClient sharedClient] fat_localizedStringForKey:@"Don't show location"]]) {
        type = @"0";
    } else if (!selectPlace.address) {
        type = @"1";
        [locationInfo setValue: selectPlace.name ?: @"" forKey:@"city"];
    } else {
        type = @"2";
        [locationInfo setValue: selectPlace.address ?: @"" forKey:@"name"];
        [locationInfo setValue: selectPlace.name ?: @"" forKey:@"address"];
    }
    [locationInfo setValue:type forKey:@"type"];
    if (self.sureBlock) {
        self.sureBlock(locationInfo);
    }
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _indicatorView.hidesWhenStopped = YES;
    }
    
    return _indicatorView;
}

#pragma mark - FATLocationResultDelegate
- (void)selectedLocationWithLocation:(FATMapPlace *)place {
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    NSString *type;
    CLLocationCoordinate2D coordinate = place.location.coordinate;
    NSMutableDictionary *locationInfo = [[NSMutableDictionary alloc] initWithDictionary:@{@"latitude" : [NSString stringWithFormat:@"%@", @(coordinate.latitude)],
                                                                                          @"longitude" : [NSString stringWithFormat:@"%@", @(coordinate.longitude)]}];
    if ([place.name isEqualToString:[[FATClient sharedClient] fat_localizedStringForKey:@"Don't show location"]]) {
        type = @"0";
    } else if (!place.address) {
        type = @"1";
        [locationInfo setValue: place.name ?: @"" forKey:@"city"];
    } else {
        type = @"2";
        [locationInfo setValue: place.address ?: @"" forKey:@"name"];
        [locationInfo setValue: place.name ?: @"" forKey:@"address"];
    }
    [locationInfo setValue:type forKey:@"type"];
    if (self.sureBlock) {
        self.sureBlock(locationInfo);
    }
}

#pragma mark - MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if (!self.userLocation) {
        _userLocation = userLocation;
        CLLocationCoordinate2D center = userLocation.location.coordinate;
        if (center.latitude > 0 && center.longitude > 0) {
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(center, 1000, 1000);
            mapView.centerCoordinate = center;
            mapView.region = region;
            
            self.locationResultVC.region = region;
        }
    }
}
// 单独加上所在的城市和不显示位置两条数据
- (void)addSpecialCity {
    // 避免重复添加。
    NSMutableArray *deleteArray = [[NSMutableArray alloc] init];
    for (FATMapPlace *place in self.dataArray) {
        if ([place.name isEqualToString:[[FATClient sharedClient] fat_localizedStringForKey:@"Don't show location"]]) {
            [deleteArray insertObject:place atIndex:0];
        }
        if (place.name && !place.address) {
            [deleteArray insertObject:place atIndex:0];
        }
    }
    if (deleteArray.count != 0) {
        [self.dataArray removeObjectsInArray:deleteArray];
    }
    
    FATMapPlace *place = [[FATMapPlace alloc] init];
    place.name = self.cityName;
    place.location = place.location;
    place.selected = NO;
    [self.dataArray insertObject:place atIndex:0];
    
    FATMapPlace *NoPlace = [[FATMapPlace alloc] init];
    NoPlace.name = [[FATClient sharedClient] fat_localizedStringForKey:@"Don't show location"];
    NoPlace.selected = NO;
    [self.dataArray insertObject:NoPlace atIndex:0];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifer = @"identifer";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifer];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    
    FATMapPlace *place = self.dataArray[indexPath.row];
    if ([place.name isEqualToString:[[FATClient sharedClient] fat_localizedStringForKey:@"Don't show location"]]) {
        cell.textLabel.textColor = [UIColor fat_colorWithRGBHexString:@"0066ff" alpha:1.0];
    } else {
        if (@available(iOS 13.0, *)) {
            cell.textLabel.textColor = UIColor.labelColor;
        } else {
            cell.textLabel.textColor = UIColor.blackColor;
        }
    }
    cell.textLabel.text = place.name;
    cell.detailTextLabel.text = place.address;
    if (place.selected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    for (FATMapPlace *place in self.dataArray) {
        place.selected = NO;
    }
    FATMapPlace *place = self.dataArray[indexPath.row];
    place.selected = YES;
    [self.tableView reloadData];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(place.location.coordinate, 1000, 1000);
    self.locationResultVC.region = region;
}

@end
