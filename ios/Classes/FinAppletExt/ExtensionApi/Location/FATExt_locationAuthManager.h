//
//  FATExt_locationAuthManager.h
//  FinAppletExt
//
//  Created by 王兆耀 on 2022/12/24.
//

#import <Foundation/Foundation.h>
#import <FinApplet/FinApplet.h>

NS_ASSUME_NONNULL_BEGIN

@interface FATExt_locationAuthManager : NSObject

+ (instancetype)shareInstance;

- (void)fat_requestAppletLocationAuthorize:(FATAppletInfo *)appletInfo isBackground:(BOOL)isBackground withComplete:(void (^)(BOOL status))complete;

@end

NS_ASSUME_NONNULL_END
