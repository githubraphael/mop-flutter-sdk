//
//  FATExtClient.m
//  FinAppletExtension
//
//  Created by Haley on 2020/8/11.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import "FATExtClient.h"
#import "FATExtBaseApi.h"
#import "FATWebView.h"
#import <FinApplet/FinApplet.h>
#import "FATExtPrivateConstant.h"
#import "FATExtMapManager.h"
#import "FATMapViewDelegate.h"
#import "FATClient+ext.h"

static FATExtClient *instance = nil;

@implementation FATExtClient

+ (instancetype)sharedClient {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FATExtClient alloc] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

+ (NSString *)SDKVersion
{
    return FATExtVersionString;
}

/// 注册地图展示类
/// @param mapClass 地图类，需要是UIView的子类，实现FATMapViewDelegate协议
- (BOOL)fat_registerMapClass:(Class)mapClass {
    if (![mapClass isSubclassOfClass:UIView.class]) {
        return NO;
    }

    if (![mapClass conformsToProtocol:@protocol(FATMapViewDelegate)]) {
        return NO;
    }
    [FATExtMapManager shareInstance].mapClass = mapClass;
    return YES;
}
- (void)registerGoogleMapService:(NSString*)apiKey placesKey:(NSString*)placeKey{
    //[GMSServices provideAPIKey: apiKey];
    [FATExtMapManager shareInstance].googleMapApiKey = apiKey;
    if(placeKey == nil || [placeKey length] == 0){
        [FATExtMapManager shareInstance].placesApiKey = apiKey;
    }else{
        [FATExtMapManager shareInstance].placesApiKey = placeKey;
    }
}

- (void)fat_prepareExtensionApis {

}

- (void)registerExtensionBLEApi {
    //该空方法不能移除。如果集成了蓝牙拓展SDK，分类会覆盖此方法
}

- (UIView *)webViewWithFrame:(CGRect)frame URL:(NSURL *)URL appletId:(NSString *)appletId {
    if (![FATClient sharedClient].inited) {
        NSLog(@"appKey invalid");
        return nil;
    }

    if (!URL || ![URL isKindOfClass:[NSURL class]]) {
        NSLog(@"URL invalid");
        return nil;
    }

    FATWebView *webView = [[FATWebView alloc] initWithFrame:frame URL:URL appletId:appletId];
    return webView;
}




@end
