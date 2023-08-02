//
//  FATExtSliderView.h
//  FinAppletGDMap
//
//  Created by 王兆耀 on 2021/12/13.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "FATMapPlace.h"

#define fatKScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define fatKScreenHeight ([UIScreen mainScreen].bounds.size.height)

NS_ASSUME_NONNULL_BEGIN

typedef void (^SelectItemBlock)(FATMapPlace *locationInfo);
typedef void (^TopDistance)(float height, BOOL isTopOrBottom);

@interface FATExtSliderView : UIView

@property (nonatomic, copy) SelectItemBlock selectItemBlock;
@property (nonatomic, assign) float topH; //上滑后距离顶部的距离
@property (nonatomic, copy) TopDistance topDistance;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<FATMapPlace *> *poiInfoListArray;

- (void)updateSearchFrameWithColcationCoordinate:(CLLocationCoordinate2D)coord;

@end

NS_ASSUME_NONNULL_END
