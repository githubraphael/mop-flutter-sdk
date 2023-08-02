//
//  FATExt_recorderManager.m
//  FinAppletExt
//
//  Created by Haley on 2021/1/21.
//  Copyright © 2021 finogeeks. All rights reserved.
//

#import "FATExt_recorderManager.h"
#import "FATExtRecordManager.h"
#import "FATClient+ext.h"

#import "FATExtUtil.h"

@implementation FATExt_recorderManager

- (void)setupApiWithSuccess:(void (^)(NSDictionary<NSString *, id> *successResult))success
                    failure:(void (^)(NSDictionary *failResult))failure
                     cancel:(void (^)(NSDictionary *cancelResult))cancel {
    NSArray *validMethods = @[@"start",@"pause",@"resume",@"stop",@"onFrameRecordedRemove"];
    NSString *method = self.method;
    if (![validMethods containsObject:method]) {
        return;
    }
    __block NSDictionary *dataDict = self.data;
    FATAppletInfo *appInfo = [[FATClient sharedClient] currentApplet];
    BOOL result = [[FATExtRecordManager shareManager] checkRecordWithMethod:method data:dataDict appletId:appInfo.appId];
    if (!result) {
        return;
    }
    if ([method isEqualToString:@"start"]) {
        [[FATClient sharedClient] fat_requestAppletAuthorize:FATAuthorizationTypeMicrophone appletId:appInfo.appId complete:^(NSInteger status) {
            if (status == 1) { //拒绝
                if (failure) {
                    failure(@{@"errMsg" : @"unauthorized,用户未授予麦克风权限"});
                }
                NSDictionary *params = @{
                    @"method" : @"onError",
                    @"data" : @{@"errMsg" : @"operateRecorder:fail fail_system permissionn denied"},
                };
                if (self.context) {
                    [self.context sendResultEvent:0 eventName:@"onRecorderManager" eventParams:params extParams:nil];
                }
                return; 
            }
            if (status == 2) { //sdk拒绝
                if (failure) {
                    failure(@{@"errMsg" : @"unauthorized disableauthorized,SDK被禁止申请麦克风权限"});
                }
                return;
            }
            dataDict = [self checkAACAuioParams:dataDict];
            [[FATExtRecordManager shareManager] startRecordWithData:dataDict appletId:appInfo.appId eventBlock:^(NSInteger eventType, NSString *eventName, NSDictionary *paramDic, NSDictionary *extDic) {
                    if (self.context) {
                        [self.context sendResultEvent:eventType eventName:eventName eventParams:paramDic extParams:extDic];
                    }
            }];
        }];
    } else if ([method isEqualToString:@"pause"]) {
        [[FATExtRecordManager shareManager] pauseRecordWithData:dataDict appletId:appInfo.appId];
    } else if ([method isEqualToString:@"resume"]) {
        [[FATExtRecordManager shareManager] resumeRecordWithData:dataDict appletId:appInfo.appId];
    } else if ([method isEqualToString:@"stop"]) {
        [[FATExtRecordManager shareManager] stopRecordWithData:dataDict appletId:appInfo.appId];
    } else if ([method isEqualToString:@"onFrameRecordedRemove"]) {
        [[FATExtRecordManager shareManager] sendRecordFrameBufferWithData:dataDict appletId:appInfo.appId];
    }
}


/// 检测录音参数，如果是aac格式的音频，并且参数都是默认值，需要把sampleRate由8000改为16000。否则会录制失败。
/// - Parameter dic: 录音参数。
- (NSDictionary *)checkAACAuioParams:(NSDictionary *)dic {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithDictionary:dic];
    if ([dic[@"format"] isEqualToString:@"aac"]) {
        NSString *encodeBitRate = dic[@"encodeBitRate"];
        NSString *sampleRate = dic[@"sampleRate"];
        NSString *numberOfChannels = dic[@"numberOfChannels"];
        if ([encodeBitRate isEqualToString:@"48000"] && [numberOfChannels isEqualToString:@"2"] && [sampleRate isEqualToString:@"8000"]) {
            [data setValue:@"16000" forKey:@"sampleRate"];
        }
    }
    return data;
}

@end

