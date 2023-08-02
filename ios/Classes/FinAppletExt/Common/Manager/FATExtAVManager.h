//
//  FATExtAVManager.h
//  FinAppletExt
//
//  Created by Haley on 2020/8/14.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^FATExtAVSuccess)(NSString *filePath);
typedef void (^FATExtAVFail)(NSString *failMsg);

@interface FATExtAVManager : NSObject

+ (instancetype)sharedManager;

/**
 开始录音

 @param success 成功回调
 @param fail 失败回调
 */
- (void)startRecordWithSuccess:(FATExtAVSuccess)success fail:(FATExtAVFail)fail;

/**
 停止录音
 */
- (void)stopRecord;

/**
 检查录音状态
 */
- (void)checkRecordState;

@end
