//
//  FATExt_invokeMapTask.m
//  FBRetainCycleDetector
//
//  Created by 王兆耀 on 2021/9/2.
//

#import "FATExt_invokeMapTask.h"
#import "FATMapView.h"
#import "FATExtMapManager.h"
#import "FATExtUtil.h"

@implementation FATExt_invokeMapTask

- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
    UIView<FATMapViewDelegate> *map = nil;
    if (self.context && [self.context respondsToSelector:@selector(getChildViewById:)]) {
        UIView *targetView = [self.context getChildViewById:self.param[@"mapId"]];
        if (targetView && [targetView conformsToProtocol:@protocol(FATMapViewDelegate)]) {
            map = (UIView<FATMapViewDelegate> *)targetView;
        }
    }
    if (!map) {
        if (failure) {
            failure(@{@"errMsg" : @"map view not exist"});
        }
        return;
    }
    if ([self.eventName isEqualToString:@"getCenterLocation"]) {
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithDictionary:[map fat_getCenter]];
        if (success) {
            success(dic);
        }
    } else if ([self.eventName isEqualToString:@"getRegion"]) {
        NSDictionary *dic = [map fat_mapgetRegion];
        if (success) {
            success(dic);
        }
    } else if ([self.eventName isEqualToString:@"getScale"]) {
        double scale = [map fat_getScale];
        if (success) {
            success(@{@"scale" : [NSNumber numberWithDouble:scale]});
        }
    } else if ([self.eventName isEqualToString:@"includePoints"]) {
        [map fat_includePoints:self.data];
        if (success) {
            success(@{});
        }
    } else if ([self.eventName isEqualToString:@"moveToLocation"]) {
        NSString *status = [map fat_moveToLocation:self.data];
        if ([status isEqualToString:@"fail"]) {
            if (failure) {
                failure(@{@"errMsg" : @"not show user location"});
            }
        } else {
            if (success) {
                success(@{});
            }
        }
    } else if ([self.eventName isEqualToString:@"fromScreenLocation"]) {
        NSDictionary *dic = [map fat_fromScreenLocation];
        if (success) {
            success(dic);
        }
    } else if ([self.eventName isEqualToString:@"toScreenLocation"]) {
        // 暂时有bug，微信端有问题。
        CGPoint point = [map fat_toScreenLocation:self.data];
        if (success) {
            success(@{@"x" : @(point.x),
                                                @"y" : @(point.y)});
        };
    } else if ([self.eventName isEqualToString:@"openMapApp"]) {
        [map fat_openMapApp:self.data];
        if (success) {
            success(@{});
        };
    } else if ([self.eventName isEqualToString:@"addMarkers"]) {
        [map fat_addMarkers:self.data];
        if (success) {
            success(@{});
        };
    } else if ([self.eventName isEqualToString:@"removeMarkers"]) {
        [map fat_removeMarkers:self.data];
        if (success) {
            success(@{});
        };
    } else if ([self.eventName isEqualToString:@"translateMarker"]) {
        BOOL isExit = [map fat_translateMarker:self.data];
        if (isExit) {
            if (success) {
                success(@{});
            };
        } else {
            if (failure) {
                failure(@{@"errMsg" : @"error markerid"});
            }
        }
    } else if ([self.eventName isEqualToString:@"moveAlong"]) {
        BOOL isExit = [map fat_moveAlong:self.data];
        if (isExit) {
            if (success) {
                success(@{});
            };
        } else {
            NSArray *pathArray = [[NSArray alloc] initWithArray:self.data[@"path"]];
            if (pathArray.count == 0 || ![pathArray isKindOfClass:[NSArray class]]) {
                if (failure) {
                    failure(@{@"errMsg" : @"parameter error: parameter.duration should be Number instead of Undefined;"});
                }
            } else {
                if (failure) {
                    failure(@{@"errMsg" : @"error markerid"});
                }
            }
        }
    } else if ([self.eventName isEqualToString:@"setCenterOffset"]) {
        if ([map respondsToSelector:@selector(mapSetCenterOffset:)]) {
            [map mapSetCenterOffset:self.data];
            if (success) {
                success(@{});
            };
        } else {
            if (failure) {
                failure(@{@"errMsg" : @"not support"});
            };
        }
    } else if ([self.eventName isEqualToString:@"getRotate"]) {
        if ([map respondsToSelector:@selector(fat_getRotate)]) {
            NSDictionary *dic = [map fat_getRotate];
            if (success) {
                success(dic);
            }
        } else {
            if (failure) {
                failure(@{@"errMsg" : @"not support"});
            };
        }
    } else if ([self.eventName isEqualToString:@"getSkew"]) {
        if ([map respondsToSelector:@selector(fat_getskew)]) {
            NSDictionary *dic = [map fat_getskew];
            if (success) {
                success(dic);
            }
        } else {
            if (failure) {
                failure(@{@"errMsg" : @"not support"});
            };
        }
    } else if ([self.eventName isEqualToString:@"initMarkerCluster"]) {
        if (failure) {
            failure(@{@"errMsg" : @"not support"});
        };
    } else if ([self.eventName isEqualToString:@"setLocMarkerIcon"]) {
        if ([map respondsToSelector:@selector(fat_setLocMarkerIcon:)]) {
            [map fat_setLocMarkerIcon:self.data];
            if (success) {
                success(@{});
            }
        } else {
            if (failure) {
                failure(@{@"errMsg" : @"not support"});
            };
        }
    }
}

@end
