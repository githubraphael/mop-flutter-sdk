//
//  FATExt_recorderManager.h
//  FinAppletExt
//
//  Created by Haley on 2021/1/21.
//  Copyright © 2021 finogeeks. All rights reserved.
//

#import "FATExtBaseApi.h"

NS_ASSUME_NONNULL_BEGIN

@interface FATExt_recorderManager : FATExtBaseApi

/**
 真实事件名
 */
@property (nonatomic, copy) NSString *method;

/**
 参数
 */
@property (nonatomic, copy) NSDictionary *data;

@end

NS_ASSUME_NONNULL_END
