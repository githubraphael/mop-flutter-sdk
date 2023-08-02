//
//  FATRecordManager.h
//  FinAppletExt
//
//  Created by Haley on 2021/1/21.
//  Copyright © 2021 finogeeks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FATExtRecordManager : NSObject

+ (instancetype)shareManager;

#pragma mark - new api
- (BOOL)startRecordWithData:(NSDictionary *)data appletId:(NSString *)appletId eventBlock:(void (^)(NSInteger eventType,NSString *eventName, NSDictionary *paramDic,NSDictionary *extDic))eventBlock;

- (BOOL)pauseRecordWithData:(NSDictionary *)data appletId:(NSString *)appletId;

- (BOOL)resumeRecordWithData:(NSDictionary *)data appletId:(NSString *)appletId;

- (BOOL)stopRecordWithData:(NSDictionary *)data appletId:(NSString *)appletId;

- (BOOL)checkRecordWithMethod:(NSString *)method data:(NSDictionary *)data appletId:(NSString *)appletId;

- (void)sendRecordFrameBufferWithData:(NSDictionary *)data appletId:(NSString *)appletId;

- (void)checkRecordState;

@end
