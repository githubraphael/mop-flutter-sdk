//
//  FATExt_invokeMapTask.h
//  FBRetainCycleDetector
//
//  Created by 王兆耀 on 2021/9/2.
//

#import "FATExtBaseApi.h"

NS_ASSUME_NONNULL_BEGIN

@interface FATExt_invokeMapTask : FATExtBaseApi

@property (nonatomic, copy) NSString *eventName;

@property (nonatomic, copy) NSString *mapId;

@property (nonatomic, copy) NSString *key;

@property (nonatomic, copy) NSDictionary *data;

@property (nonatomic, assign) NSInteger nativeViewId;

@end

NS_ASSUME_NONNULL_END
