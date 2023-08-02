//
//  FATExt_insertNativeMap.m
//  FinAppletExt
//
//  Created by 滔 on 2022/9/18.
//  Copyright © 2022 finogeeks. All rights reserved.
//

#import "FATExt_insertNativeMap.h"
#import "FATMapViewDelegate.h"
#import "FATMapView.h"
#import "FATExtMapManager.h"

@implementation FATExt_insertNativeMap

- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
    UIView<FATMapViewDelegate> *mapObject = [[FATExtMapManager shareInstance].mapClass alloc];
    UIView<FATMapViewDelegate> *mapView = [mapObject initWithParam:self.param mapPageId:self.appletInfo.appId];
    mapView.eventCallBack = ^(NSString *eventName, NSDictionary *paramDic) {
        if (self.context) {
            [self.context sendResultEvent:1 eventName:eventName eventParams:paramDic extParams:nil];
        }
    };
    if (self.context && [self.context respondsToSelector:@selector(insertChildView:viewId:parentViewId:isFixed:isHidden:)]) {
        NSString *parentId = self.param[@"cid"];
        if (parentId && parentId.length > 0) { //同层渲染
            CGRect frame = mapView.frame;
            frame.origin = CGPointZero;
            mapView.frame = frame;
        }
        BOOL isHidden = [self.param[@"hide"] boolValue];
        NSString *viewId = [self.context insertChildView:mapView viewId:self.param[@"mapId"] parentViewId:self.param[@"cid"] isFixed:NO isHidden:isHidden];
        if (viewId && viewId.length > 0) {
            if (success) {
                success(@{});
            }
        } else {
            if (failure) {
                failure(@{});
            }
        }
    } else {
        if (failure) {
            failure(@{});
        }
    }
}
@end
