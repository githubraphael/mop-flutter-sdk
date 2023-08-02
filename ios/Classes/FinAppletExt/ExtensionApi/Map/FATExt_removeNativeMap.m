//
//  FATExt_removeNativeMap.m
//  FinAppletExt
//
//  Created by 滔 on 2022/9/18.
//  Copyright © 2022 finogeeks. All rights reserved.
//

#import "FATExt_removeNativeMap.h"

@implementation FATExt_removeNativeMap
- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
    if (self.context && [self.context respondsToSelector:@selector(removeChildView:)]) {
        BOOL result = [self.context removeChildView:self.param[@"mapId"]];
        if (result) {
            if (success) {
                success(@{});
            }
        } else {
            if (failure) {
                failure(@{});
            }
        }
    } else {
        if (failure) {
            failure(@{});
        }
    }
}
@end
