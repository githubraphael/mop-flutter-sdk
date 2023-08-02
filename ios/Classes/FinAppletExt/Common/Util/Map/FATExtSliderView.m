//
//  FATExtSliderView.m
//  FinAppletGDMap
//
//  Created by 王兆耀 on 2021/12/13.
//

#import "FATExtSliderView.h"
#import "UIView+FATExtFrame.h"
#import <FinApplet/FinApplet.h>
#import "UIView+FATExtSafaFrame.h"
#import "FATExtUtil.h"
#import "FATExtMapManager.h"

@interface FATExtSliderView () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UISearchControllerDelegate, UISearchBarDelegate>

@property (nonatomic, assign) float bottomH; //下滑后距离顶部的距离
@property (nonatomic, assign) float stop_y;  //tableView滑动停止的位置
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray<FATMapPlace *> *tempPoiInfoListArray;
@property (nonatomic, assign) NSInteger selectNumber;
@property (nonatomic, strong) UISearchController *search;
@property (nonatomic, assign) CLLocationCoordinate2D locationCoordinate;
@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, strong) NSString *cityString;
@property (nonatomic, assign) MKCoordinateRegion region;
@end

@implementation FATExtSliderView

- (NSMutableArray<FATMapPlace *> *)poiInfoListArray {
    if (!_poiInfoListArray) {
        _poiInfoListArray = [[NSMutableArray alloc] init];
    }
    return _poiInfoListArray;
}

- (NSMutableArray<FATMapPlace *> *)tempPoiInfoListArray {
    if (!_tempPoiInfoListArray) {
        _tempPoiInfoListArray = [[NSMutableArray alloc] init];
    }
    return _tempPoiInfoListArray;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUI];
    }
    return self;
}

- (void)setUI {
    self.backgroundColor = [UIColor systemGrayColor];
    self.bottomH = self.top;
    self.pageIndex = 0;
    self.selectNumber = 0;
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    panGestureRecognizer.delegate = self;
    [self addGestureRecognizer:panGestureRecognizer];
    [self creatUI];
}

- (void)creatUI {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, fatKScreenWidth, self.frame.size.height) style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.bounces = NO;
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        // Fallback on earlier versions
    }
    [self addSubview:self.tableView];
    [self.tableView registerNib:[UINib nibWithNibName:@"SlideTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"SlideTableViewCell"];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.search.delegate = self;
}

- (void)getData {
    CLLocationCoordinate2D centerCoordinate = self.locationCoordinate;
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude];

    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *array, NSError *error) {
        CLPlacemark *placemark = nil;
        if (!error) {
            placemark = [array firstObject];
        }
        
        MKCoordinateSpan span = MKCoordinateSpanMake(centerCoordinate.latitude, centerCoordinate.longitude);
        MKCoordinateRegion newRegion = MKCoordinateRegionMake(centerCoordinate, span);
        
        MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
        request.region = self.region;
        request.naturalLanguageQuery = @"Place";
        CLLocationCoordinate2D destCenter = self.region.center;
        if(destCenter.latitude == 0){
            destCenter = centerCoordinate;
        }
        
        if([FATExtMapManager shareInstance].googleMapApiKey.length > 1){
            [FATExtUtil getNearbyPlacesByCategory:@"All" coordinates:destCenter radius:1000 token:@""
                                                   completion:^(NSDictionary * _Nonnull dict) {
                NSMutableArray *placeArrayM = [NSMutableArray array];
                if (placemark) {
                    FATMapPlace *place = [[FATMapPlace alloc] init];
                    place.name = placemark.name;
                    place.address = placemark.thoroughfare;
                    place.location = placemark.location;
                    place.selected = YES;
                    [placeArrayM addObject:place];
                }
                [placeArrayM addObjectsFromArray:[FATExtUtil convertPlaceDictToArray:dict]];
                self.poiInfoListArray = [[NSMutableArray alloc] initWithArray: placeArrayM];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }];
        }else{
            MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:request];
            [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *_Nullable response, NSError *_Nullable error) {
                NSMutableArray *placeArrayM = [NSMutableArray array];
                for (MKMapItem *item in response.mapItems) {
                    if (!item.isCurrentLocation) {
                        FATMapPlace *place = [[FATMapPlace alloc] init];
                        place.name = item.placemark.name;
                        place.address = item.placemark.thoroughfare;
                        place.location = item.placemark.location;
                        [placeArrayM addObject:place];
                    }
                }
                self.poiInfoListArray = [[NSMutableArray alloc] initWithArray:placeArrayM];
                [self.tableView reloadData];
            }];
        }
    }];
}

- (void)updateSearchFrameWithColcationCoordinate:(CLLocationCoordinate2D)coord {
//    struct CLLocationCoordinate2D my2D = {40.0, 115.0};//self.locationCoordinate
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.locationCoordinate, 1000, 1000);
    self.region = region;
    self.locationCoordinate = coord;
    [self.poiInfoListArray removeAllObjects];
    [self.tableView reloadData];
    [self getData];
}

- (void)p_searchLocationsWithSearchText:(NSString *)searchText {
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.region = self.region;
    request.naturalLanguageQuery = searchText;
    CLLocationCoordinate2D destCenter = self.region.center;
    if(destCenter.latitude == 0){
        destCenter = self.locationCoordinate;
    }
    
    if([FATExtMapManager shareInstance].googleMapApiKey.length > 1){
        [FATExtUtil getNearbyPlacesByCategory:searchText coordinates:destCenter radius:1000 token:@""
                                               completion:^(NSDictionary * _Nonnull dict) {
            
            self.poiInfoListArray = [[NSMutableArray alloc] initWithArray: [FATExtUtil convertPlaceDictToArray:dict]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
    }else { MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:request];
        [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *_Nullable response, NSError *_Nullable error) {
            NSMutableArray *placeArrayM = [NSMutableArray array];
            for (MKMapItem *item in response.mapItems) {
                if (!item.isCurrentLocation) {
                    FATMapPlace *place = [[FATMapPlace alloc] init];
                    place.name = item.placemark.name;
                    place.address = item.placemark.thoroughfare;
                    place.location = item.placemark.location;
                    [placeArrayM addObject:place];
                }
            }
            self.poiInfoListArray = [[NSMutableArray alloc] initWithArray:placeArrayM];
            [self.tableView reloadData];
        }];
    }
}

#pragma mark - 滑动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat currentPostion = scrollView.contentOffset.y;
    self.stop_y = currentPostion;
    
    if (self.top > self.topH) {
        [scrollView setContentOffset:CGPointMake(0, 0)];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)panAction:(UIPanGestureRecognizer *)pan {
    // 获取视图偏移量
    CGPoint point = [pan translationInView:self];
    // stop_y是tableview的偏移量，当tableview的偏移量大于0时则不去处理视图滑动的事件
    if (self.stop_y > 0) {
        // 将视频偏移量重置为0
        [pan setTranslation:CGPointMake(0, 0) inView:self];
        return;
    }
    
    // self.top是视图距离顶部的距离
    self.top += point.y;
    if (self.top < self.topH) {
        self.top = self.topH;
    }
    
    // self.bottomH是视图在底部时距离顶部的距离
    if (self.top > self.bottomH) {
        self.top = self.bottomH;
    }
    
    // 在滑动手势结束时判断滑动视图距离顶部的距离是否超过了屏幕的一半，如果超过了一半就往下滑到底部
    // 如果小于一半就往上滑到顶部
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        // 滑动速度
        CGPoint velocity = [pan velocityInView:self];
        CGFloat speed = 350;
        if (velocity.y < -speed) {
            [self goTop];
            [pan setTranslation:CGPointMake(0, 0) inView:self];
            return;
        } else if (velocity.y > speed) {
            [self goBack];
            [pan setTranslation:CGPointMake(0, 0) inView:self];
            return;
        }
        
        if (self.top > fatKScreenHeight / 2) {
            [self goBack];
        } else {
            [self goTop];
        }
    }
    
    [pan setTranslation:CGPointMake(0, 0) inView:self];
    if (self.top != self.bottomH) {
        if (!isnan(point.y)) {
            if (self.topDistance) {
                self.topDistance(point.y, false);
            }
        }
    }
}

- (void)goTop {
    if (self.top != self.bottomH) {
        if (self.topDistance) {
            if (!isnan(self.topH)) {
                self.topDistance(self.topH, true);
            }
        }
    }
    [UIView animateWithDuration:0.5 animations:^{
        self.top = self.topH;
    } completion:^(BOOL finished){
        
    }];
}

- (void)goBack {
    if (self.topDistance) {
        if (!isnan(self.bottomH)) {
            self.topDistance(self.bottomH, true);
        }
    }
    [UIView animateWithDuration:0.5 animations:^{
        self.top = self.bottomH;
    } completion:^(BOOL finished){
        //        self.tableView.userInteractionEnabled = NO;
    }];
}

#pragma mark - UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.poiInfoListArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifer = @"identifer";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifer];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    
    cell.textLabel.text = self.poiInfoListArray[indexPath.row].name;
    cell.detailTextLabel.text = self.poiInfoListArray[indexPath.row].address;
    if (indexPath.row == self.selectNumber) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    self.selectNumber = indexPath.row;
    [tableView reloadData];
    FATMapPlace *poiInfo = self.poiInfoListArray[indexPath.row];
    if (self.selectItemBlock) {
        self.selectItemBlock(poiInfo);
    }
}

#pragma mark - UISearchResultsUpdating

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self goTop];
    self.tempPoiInfoListArray = [[NSMutableArray alloc] initWithArray:self.poiInfoListArray];
    [self.poiInfoListArray removeAllObjects];
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.selectNumber = -1;
    NSString *searchString = self.searchController.searchBar.text;
    [self p_searchLocationsWithSearchText:searchString];
    self.searchController.active = NO;
    [self goBack];
    self.searchController.searchBar.text = searchString;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self goBack];
    self.poiInfoListArray = [[NSMutableArray alloc] initWithArray:self.tempPoiInfoListArray];
    [self.tableView reloadData];
}

- (UISearchController *)searchController {
    if (!_searchController) {
        _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        _searchController.searchBar.delegate = self;
        _searchController.dimsBackgroundDuringPresentation = NO;
        _searchController.hidesNavigationBarDuringPresentation = NO;
        _searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _searchController.searchBar.frame = CGRectMake(0, 0, fatKScreenWidth, 44);
        NSString *placeholder = [[FATClient sharedClient] fat_localizedStringForKey:@"Search for location"];
        _searchController.searchBar.placeholder = placeholder;
    }
    return _searchController;
}

@end
