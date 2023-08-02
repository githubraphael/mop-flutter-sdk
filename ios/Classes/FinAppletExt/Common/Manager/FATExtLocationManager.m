//
//  FATExtLocationManager.m
//  FinAppletExt
//
//  Created by beetle_92 on 2022/8/19.
//  Copyright © 2022 finogeeks. All rights reserved.
//

#import "FATExtLocationManager.h"
#import "FATExtAVManager.h"
#import "FATExtRecordManager.h"
#import "FATExt_LocationUpdateManager.h"

#import <FinApplet/FinApplet.h>

@implementation FATExtLocationManager

- (void)startUpdatingLocation {
    [super startUpdatingLocation];
    if ([self.delegate isKindOfClass:NSClassFromString(@"FATMapView")]) {
        return;
    }
    // 胶囊按钮
    UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
    UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
    if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
        [nav controlCapsuleStateButton:NO state:FATCapsuleButtonStateLocation animate:YES];
    }
}

- (void)stopUpdatingLocation {
    [super stopUpdatingLocation];
    // 胶囊按钮
    UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
    UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
    if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [nav controlCapsuleStateButton:YES state:FATCapsuleButtonStateLocation animate:NO];
            [[FATExtAVManager sharedManager] checkRecordState];
            [[FATExtRecordManager shareManager] checkRecordState];
            [[FATExt_LocationUpdateManager sharedManager] checkLocationState];
            
        });
    }
}

@end
