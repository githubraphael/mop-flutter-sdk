//
//  SDKCoreClient.h
//  fincore
//
//  Created by gordanyang on 2021/8/29.
//

#import <Foundation/Foundation.h>
#import "FinLicenseService.h"
NS_ASSUME_NONNULL_BEGIN

@interface SDKCoreClient : NSObject
+ (instancetype)sharedInstance;

@property (nonatomic, strong, readonly) FinLicenseService *finoLicenseService;

@end

NS_ASSUME_NONNULL_END
