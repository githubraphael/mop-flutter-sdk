//
//  FATExtRecorder.h
//  HLProject
//
//  Created by Haley on 2021/12/28.
//  Copyright © 2021 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef NS_ENUM(NSUInteger, FATFrameState) {
    FATFrameStatePrepareToSend,
    FATFrameStateAlreadyWillSend,
    FATFrameStateAlreadySent
};

@class FATExtRecorder;
@protocol FATExtRecorderDelegate <NSObject>

- (void)extRecorder:(FATExtRecorder *)recorder
        onFrameData:(NSData *)frameData
         frameIndex:(NSInteger)frameIndex
        isLastFrame:(BOOL)isLastFrame;

- (void)extRecorderDidCompletion:(FATExtRecorder *)recorder;

- (void)extRecorderBeginInterruption:(FATExtRecorder *)recorder;

- (void)extRecorderEndInterruption:(FATExtRecorder *)recorder withOptions:(NSUInteger)flags;

- (void)extRecorder:(FATExtRecorder *)recorder onError:(NSError *)error;

@end

@interface FATExtRecorder : NSObject

@property (nonatomic, assign) BOOL isStarted;

@property (nonatomic, assign) BOOL isRecording;

@property (nonatomic, assign) BOOL isPausing;

@property (nonatomic, strong) NSString *recordFilePath;

@property (nonatomic, weak) id<FATExtRecorderDelegate> delegate;

@property (nonatomic, readonly, copy) NSString *recorderId;

@property (nonatomic, strong) NSMutableArray *frameInfoArray;

@property (nonatomic, assign) FATFrameState frameState;

@property (nonatomic, assign) BOOL waitToSendBuffer;

@property (nonatomic, copy) void(^eventCallBack)(NSInteger eventType,NSString *eventName, NSDictionary *paramDic,NSDictionary *extDic);

- (BOOL)startRecordWithDict:(NSDictionary *)dict appId:(NSString *)appId;

- (BOOL)pauseRecord;

- (BOOL)resumeRecord;

- (BOOL)stopRecord;

@end
