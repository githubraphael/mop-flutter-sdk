//
//  FATExt_getLocation.h
//  FinAppletExt
//
//  Created by Haley on 2020/12/10.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import "FATExtBaseApi.h"

@interface FATExt_getLocation : FATExtBaseApi

@property (nonatomic, copy) NSString *type;

@property (nonatomic, assign) BOOL altitude;

@property (nonatomic, assign) BOOL isHighAccuracy;

@property (nonatomic, assign) NSInteger highAccuracyExpireTime;


@end
