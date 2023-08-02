//
//  FATMapViewDelegate.h
//  FinAppletExt
//
//  Created by 王滔 on 2021/11/24.
//  Copyright © 2021 finogeeks. All rights reserved.
//

#ifndef FATMapViewDelegate_h
#define FATMapViewDelegate_h

#import <UIKit/UIKit.h>

@protocol FATMapViewDelegate <NSObject>

@required

/// 发送Subscribe事件给page层
/// eventName  事件名
///  resultDic 事件的参数
@property (nonatomic, copy) void(^eventCallBack)(NSString *eventName, NSDictionary *paramDic);

- (instancetype)initWithParam:(NSDictionary *)param mapPageId:(NSString *)pageId;

- (void)updateWithParam:(NSDictionary *)param;

/// 获取中心点的经纬度
- (NSDictionary *)fat_getCenter;

/// 计算缩放级别
- (double)fat_getScale;

/// 移动到指定位置
/// @param data 要移动的经纬度
- (NSString *)fat_moveToLocation:(NSDictionary *)data;

/// 缩放地图，展示所有的经纬度
/// @param data 对应的数据
- (void)fat_includePoints:(NSDictionary *)data;

/// 获取左下，右上角的经纬度信息
- (NSDictionary *)fat_mapgetRegion;

/// 获取屏幕上的点对应的经纬度，坐标原点为地图左上角。
- (NSDictionary *)fat_fromScreenLocation;

/// 获取经纬度对应的屏幕坐标，坐标原点为地图左上角
/// @param data 包含经纬度信息
- (CGPoint)fat_toScreenLocation:(NSDictionary *)data;

///// 打开地图app进行导航
- (void)fat_openMapApp:(NSDictionary *)data;

/// 在地图上添加大头针
- (void)fat_addMarkers:(NSDictionary *)data;

/// 在地图上移除大头针
- (void)fat_removeMarkers:(NSDictionary *)data;

/// 在地图上平移大头针
- (BOOL)fat_translateMarker:(NSDictionary *)data;

/// 沿指定路径移动 marker
- (BOOL)fat_moveAlong:(NSDictionary *)data;

@optional

/// 设置地图中心点偏移，向后向下为增长，屏幕比例范围(0.25~0.75)，默认偏移为[0.5, 0.5]
- (void)mapSetCenterOffset:(NSDictionary *)data;

- (void)fat_setLocMarkerIcon:(NSDictionary *)data;

/// 获取当前地图的旋转角，地图sdk未实现返回nil
- (NSDictionary *)fat_getRotate;

/// 获取当前地图的倾斜角
- (NSDictionary *)fat_getskew;

/// 用于customCallout的数据更新
- (void)updateNativeMapMarkers:(NSDictionary *)param;

@end

#endif /* FATMapViewDelegate_h */
