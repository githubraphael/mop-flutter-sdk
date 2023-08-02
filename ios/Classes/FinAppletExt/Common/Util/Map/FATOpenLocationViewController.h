//
//  FATOpenLocationViewController.h
//  FinAppletExt
//
//  Created by 王兆耀 on 2021/12/9.
//

#import <UIKit/UIKit.h>
#import <FinApplet/FinApplet.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SureBlock)(NSDictionary *locationInfo);

@interface FATOpenLocationViewController : FATUIViewController

@property (nonatomic, copy) dispatch_block_t cancelBlock;
@property (nonatomic, copy) SureBlock sureBlock;

/// 目标地纬度
@property (nonatomic, strong) NSString *latitude;
/// 目标地经度
@property (nonatomic, strong) NSString *longitude;

@property (nonatomic, strong) NSString *scale;

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSString *address;

@end

NS_ASSUME_NONNULL_END
