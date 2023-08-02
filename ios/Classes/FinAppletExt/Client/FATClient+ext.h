//
//  FATClient+ext.h
//  Pods
//
//  Created by 王滔 on 2021/11/15.
//

#ifndef FATClient_ext_h
#define FATClient_ext_h

#import <FinApplet/FinApplet.h>

@interface FATClient (FATAppletExt)

/// 获取小程序的权限
/// @param authType  权限类型，0:相册 1:相机 2:麦克风 3:位置
/// @param appletId  小程序id
/// @param complete 结果回调 status: 0 允许 1:用户拒绝 2: sdk拒绝
- (void)fat_requestAppletAuthorize:(FATAuthorizationType)authType appletId:(NSString *)appletId complete:(void (^)(NSInteger status))complete;

///  内部sdk注入API方法，包括扩展sdk和其他地图等sdk 注入的API会加到内部白名单列表，保证小程序在设置了api白名单的情况下，也能正常响应
/// @param extApiName  API名称
/// @param handler  回调
- (BOOL)registerInnerExtensionApi:(NSString *)extApiName  handler:(void (^)(FATAppletInfo *appletInfo, id param, FATExtensionApiCallback callback))handler;

/**
 内部sdk注入API方法，包括扩展sdk和其他地图等sdk 注入的API会加到内部白名单列表，保证小程序在设置了api白名单的情况下，也能正常响应
 @param syncExtApiName 扩展的api名称
 @param handler 回调
 @return 返回注册结果
 */
- (BOOL)registerInnerSyncExtensionApi:(NSString *)syncExtApiName handler:(NSDictionary *(^)(FATAppletInfo *appletInfo, id param))handler;


/**
 为HTML 注册要调用的原生 api（内部sdk注入的api）
 @param webApiName 原生api名字
 @param handler 回调
 */
- (BOOL)fat_registerInnerWebApi:(NSString *)webApiName handler:(void (^)(FATAppletInfo *appletInfo, id param, FATExtensionApiCallback callback))handler;



@end

#endif /* FATClient_ext_h */
