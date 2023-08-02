//
//  FATExt_chooseLocation.h
//  FinAppletExt
//
//  Created by Haley on 2020/8/19.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import "FATExtBaseApi.h"

@interface FATExt_chooseLocation : FATExtBaseApi
/// 目标地纬度
@property (nonatomic, strong) NSString *latitude;
/// 目标地经度
@property (nonatomic, strong) NSString *longitude;

@end
