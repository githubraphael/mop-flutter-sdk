//
//  FATExtBaseApi.h
//  FinAppletExtension
//
//  Created by Haley on 2020/8/11.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FinApplet/FinApplet.h>

@class FATAppletInfo;

@protocol FATApiHanderContextDelegate <NSObject>
//获取当前控制器
- (UIViewController *)getCurrentViewController;

//获取当前的页面id
- (NSString *)getCurrentPageId;

/// API发送回调事件给service层或者page层
/// eventName  事件名
/// eventType 0: service层订阅事件(callSubscribeHandlerWithEvent)  1:page层订阅事件(callSubscribeHandlerWithEvent)  int类型方便以后有需要再添加事件类型
/// paramDic 回调事件的参数
///  extDic 扩展参数，预留字段，方便以后扩展  可以包含webId，表示发送事件给某个指定页面  service事件可以包含jsContextKey和jsContextValue，可以给分包service的JSContext设置值，用在数据帧
- (void)sendResultEvent:(NSInteger)eventType eventName:(NSString *)eventName eventParams:(NSDictionary *)param extParams:(NSDictionary *)extDic;

@optional

- (NSString *)insertChildView:(UIView *)childView viewId:(NSString *)viewId parentViewId:(NSString *)parentViewId  isFixed:(BOOL)isFixed isHidden:(BOOL)isHidden;

//更新hide属性为NO时使用
/// @param childView  原生视图
/// @param viewId  原生视图id
/// @param parentViewId  原生视图父视图id，即WkScrollView的id，对应事件的cid
/// @param isFixed  同层渲染这个字段不起作用，传NO或YES都可以，非同层渲染生效，传NO则组件会跟着页面滚动，传YES则组件固定在页面上，不会随着滚动
- (void)updateChildViewHideProperty:(UIView *)childView viewId:(NSString *)viewId parentViewId:(NSString *)parentViewId isFixed:(BOOL)isFixed isHidden:(BOOL)isHidden complete:(void(^)(BOOL result))complete;


- (UIView *)getChildViewById:(NSString *)viewId;

- (BOOL)removeChildView:(NSString *)viewId;

@end

@protocol FATApiProtocol <NSObject>

@required

@property (nonatomic, strong) FATAppletInfo *appletInfo;

/**
 api名称
 */
@property (nonatomic, readonly, copy) NSString *command;

/**
 原始参数
 */
@property (nonatomic, readonly, copy) NSDictionary<NSString *, id> *param;

@property (nonatomic, weak) id<FATApiHanderContextDelegate> context;


/**
 设置API, 子类重写

 @param success 成功回调
 @param failure 失败回调
 @param cancel 取消回调
 */
- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel;

@optional
/**
 同步api，子类重写
 */
- (NSString *)setupSyncApi;

@end

@interface FATExtBaseApi : NSObject<FATApiProtocol>

@property (nonatomic, copy, readonly) NSDictionary *param;

@property (nonatomic, strong) FATAppletInfo *appletInfo;

/**
 api名称
 */
@property (nonatomic, readonly, copy) NSString *command;

@property (nonatomic, weak) id<FATApiHanderContextDelegate> context;


//+ (FATExtBaseApi *)apiWithCommand:(NSString *)command param:(NSDictionary *)param;

//- (void)setupApiWithCallback:(FATExtensionApiCallback)callback;

//创建API对象，用于地图sdk的API，地图的API有点特殊，如果用户使用了高德或者百度地图，需要创建对应sdk的API对象
+ (id<FATApiProtocol>)fat_apiWithApiClass:(NSString *)apiClassName params:(NSDictionary *)params;

@end
