//
// Copyright (c) 2017, finogeeks.com
// All rights reserved.
//
//
//

#import "FATExt_stopRecord.h"
#import "FATExtAVManager.h"

@implementation FATExt_stopRecord

- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
    [[FATExtAVManager sharedManager] stopRecord];
    if (success) {
        success(@{});
    }
}

@end
