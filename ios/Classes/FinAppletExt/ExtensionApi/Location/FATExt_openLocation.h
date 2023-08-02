//
//  FATExt_openLocation.h
//  FinAppletExt
//
//  Created by 王兆耀 on 2021/12/7.
//

#import "FATExtBaseApi.h"

NS_ASSUME_NONNULL_BEGIN

@interface FATExt_openLocation : FATExtBaseApi

/// 目标地纬度
@property (nonatomic, strong) NSString *latitude;
/// 目标地经度
@property (nonatomic, strong) NSString *longitude;

@property (nonatomic, strong) NSString *scale;

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSString *address;

@end

NS_ASSUME_NONNULL_END
