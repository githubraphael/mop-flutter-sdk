//
//  FATWGS84ConvertToGCJ02.h
//  FinApplet
//
//  Created by 杨涛 on 2018/8/9.
//  Copyright © 2018年 finogeeks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface FATWGS84ConvertToGCJ02ForAMapView : NSObject
//判断是否已经超出中国范围
+ (BOOL)isLocationOutOfChina:(CLLocationCoordinate2D)location;
//转GCJ-02
+ (CLLocationCoordinate2D)transformFromWGSToGCJ:(CLLocationCoordinate2D)wgsLoc;
// gcj02转wgs82
+ (CLLocationCoordinate2D)transformFromGCJToWGS:(CLLocationCoordinate2D)wgsLoc;
@end
