//
//  FATLocationResultViewController.m
//  AppletDemo
//
//  Created by Haley on 2020/4/17.
//  Copyright © 2020 weidian. All rights reserved.
//

#import "FATLocationResultViewController.h"
#import "FATExtMapManager.h"
#import "FATExtUtil.h"


@interface FATLocationResultViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, copy) NSArray<FATMapPlace *> *places;

@property (nonatomic, strong) FATMapPlace *selectedPlace;

@end

@implementation FATLocationResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self p_initSubViews];
}

#pragma mark - private method
- (void)p_initSubViews {
    self.edgesForExtendedLayout = UIRectEdgeNone;
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.searchBarHeight, width, height - self.searchBarHeight - 60) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 60;
    [self.view addSubview:self.tableView];
}

- (void)p_searchLocationsWithSearchText:(NSString *)searchText {
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.region = self.region;
    request.naturalLanguageQuery = searchText;

    MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:request];
    if([FATExtMapManager shareInstance].googleMapApiKey.length > 1){
        [FATExtUtil getNearbyPlacesByCategory:searchText coordinates:self.region.center radius:1000 token:@""
                                               completion:^(NSDictionary * _Nonnull dict) {
            self.places = [[FATExtUtil convertPlaceDictToArray:dict] copy];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
    }else{[localSearch startWithCompletionHandler:^(MKLocalSearchResponse *_Nullable response, NSError *_Nullable error) {
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
        self.places = [placeArrayM copy];
        [self.tableView reloadData];
    }];
    }
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    [self p_searchLocationsWithSearchText:searchString];
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.places.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifer = @"placeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifer];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }

    FATMapPlace *place = self.places[indexPath.row];
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
    for (FATMapPlace *place in self.places) {
        place.selected = NO;
    }
    FATMapPlace *place = self.places[indexPath.row];
    place.selected = YES;
    [self.tableView reloadData];

    if (self.delegate && [self.delegate respondsToSelector:@selector(selectedLocationWithLocation:)]) {
        [self.delegate selectedLocationWithLocation:place];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
