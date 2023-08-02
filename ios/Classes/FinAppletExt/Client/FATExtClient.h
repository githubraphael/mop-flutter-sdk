//
//  FATExtClient.h
//  FinAppletExtension
//
//  Created by Haley on 2020/8/11.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FATExtClient : NSObject

+ (instancetype)sharedClient;

/// 版本号
+ (NSString *)SDKVersion;

- (void)fat_prepareExtensionApis;

- (void)registerGoogleMapService:(NSString*)apiKey placesKey:(NSString*)placeKey;

/// 获取webView
/// @param frame frame
/// @param URL 网页的URL
/// @param appletId 小程序ID
- (UIView *)webViewWithFrame:(CGRect)frame URL:(NSURL *)URL appletId:(NSString *)appletId;

@end
