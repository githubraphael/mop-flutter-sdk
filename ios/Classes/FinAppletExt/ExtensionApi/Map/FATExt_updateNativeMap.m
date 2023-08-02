//
//  FATExt_updateNativeMap.m
//  FinAppletExt
//
//  Created by 滔 on 2022/9/18.
//  Copyright © 2022 finogeeks. All rights reserved.
//

#import "FATExt_updateNativeMap.h"
#import "FATMapViewDelegate.h"

@implementation FATExt_updateNativeMap

- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
    if (self.context && [self.context respondsToSelector:@selector(getChildViewById:)]) {
        UIView *targetView = [self.context getChildViewById:self.param[@"mapId"]];
        if (targetView && [targetView conformsToProtocol:@protocol(FATMapViewDelegate)]) {
            UIView<FATMapViewDelegate> *mapView = (UIView<FATMapViewDelegate> *)targetView;
            if (mapView && [mapView respondsToSelector:@selector(updateWithParam:)]) {
                //是否是更新hide属性
                if ([self.param objectForKey:@"hide"]) {
                    BOOL hide = [[self.param objectForKey:@"hide"] boolValue];
                    if (hide) {
                        [targetView removeFromSuperview];
                    } else {
                        if (self.context && [self.context respondsToSelector:@selector(updateChildViewHideProperty:viewId:parentViewId:isFixed:isHidden:complete:)]) {
                            [self.context updateChildViewHideProperty:targetView viewId:self.param[@"mapId"] parentViewId:self.param[@"cid"] isFixed:NO isHidden:hide complete:nil];
                        }
                    }
                }
                [mapView updateWithParam:self.param];
                if (success) {
                    success(@{});
                }
            } else {
                if (failure) {
                    NSDictionary *dictParam = @{};
                    failure(dictParam);
                }
            }
        }
    } else {
        if (failure) {
            NSDictionary *dictParam = @{};
            failure(dictParam);
        }
    }
}
@end
