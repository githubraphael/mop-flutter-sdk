//
// Copyright (c) 2017, finogeeks.com
// All rights reserved.
//
//
//

#import "FATExt_startRecord.h"
#import "FATExtAVManager.h"
#import "FATClient+ext.h"

#import <AVFoundation/AVFoundation.h>

@implementation FATExt_startRecord

- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
    FATAppletInfo *appInfo = [[FATClient sharedClient] currentApplet];
    [[FATClient sharedClient] fat_requestAppletAuthorize:FATAuthorizationTypeMicrophone appletId:appInfo.appId complete:^(NSInteger status) {
        if (status == 1) {
            if (failure) {
                failure(@{@"errMsg" : @"unauthorized,用户未授予麦克风权限"});
            }
            return;
        } else if (status == 2) {
            if (failure) {
                failure(@{@"errMsg" : @"unauthorized disableauthorized,SDK被禁止申请麦克风权限"});
            }
            return;
        }
        [[FATExtAVManager sharedManager] startRecordWithSuccess:^(NSString *tempFilePath) {
            if (success) {
                success(@{@"tempFilePath" : tempFilePath});
            }
        } fail:^(NSString *msg) {
            if (failure) {
                failure(@{@"errMsg" : msg});
            }
        }];
    }];
}

@end
