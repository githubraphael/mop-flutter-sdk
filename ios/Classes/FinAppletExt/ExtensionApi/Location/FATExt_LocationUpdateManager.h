//
//  FATExt_LocationUpdateManager.h
//  FinAppletExt
//
//  Created by 王兆耀 on 2022/11/6.
//

#import <Foundation/Foundation.h>
#import "FATExtBaseApi.h"
#import "FATExtLocationManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FATExt_LocationUpdateManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong) FATExtLocationManager *locationManager;

@property (nonatomic, assign) BOOL locationIsInit;

@property (nonatomic, copy) NSString *appletId;

@property (nonatomic, weak) id<FATApiHanderContextDelegate> context;

- (void)startLocationUpdateType:(NSString *)type isAllowsBackgroundLocationUpdates:(BOOL)result withAppId:(NSString *)appId Success:(void (^)(NSDictionary<NSString *, id> *successResult))success
                        failure:(void (^)(NSDictionary *failResult))failure
                         cancel:(void (^)(NSDictionary *cancelResult))cancel;

- (void)onLocationUpdate;

- (void)stopLocationUpdate;

- (void)checkLocationState;

@end

NS_ASSUME_NONNULL_END
