//
//  FATMapViewController.h
//  AppletDemo
//
//  Created by Haley on 2020/4/16.
//  Copyright © 2020 weidian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FinApplet/FinApplet.h>

typedef void (^SureBlock)(NSDictionary *locationInfo);

@interface FATMapViewController : FATUIViewController

@property (nonatomic, copy) dispatch_block_t cancelBlock;
@property (nonatomic, copy) SureBlock sureBlock;

/// 目标地纬度
@property (nonatomic, strong) NSString *latitude;
/// 目标地经度
@property (nonatomic, strong) NSString *longitude;

@end
