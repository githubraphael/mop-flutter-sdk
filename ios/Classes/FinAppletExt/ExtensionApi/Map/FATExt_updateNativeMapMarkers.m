//
//  FATExt_updateNativeMapMarkers.m
//  FinAppletExt
//
//  Created by 滔 on 2022/9/18.
//  Copyright © 2022 finogeeks. All rights reserved.
//

#import "FATExt_updateNativeMapMarkers.h"
#import "FATMapViewDelegate.h"

@implementation FATExt_updateNativeMapMarkers
- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
    
    if (self.context && [self.context respondsToSelector:@selector(getChildViewById:)]) {
        UIView *targetView = [self.context getChildViewById:self.param[@"mapId"]];
        if (targetView && [targetView conformsToProtocol:@protocol(FATMapViewDelegate)]) {
            UIView<FATMapViewDelegate> *mapView = (UIView<FATMapViewDelegate> *)targetView;
            if (mapView && [mapView respondsToSelector:@selector(updateNativeMapMarkers:)]) {
                [mapView updateNativeMapMarkers:self.param];
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
