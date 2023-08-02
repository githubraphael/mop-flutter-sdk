//
//  FATRecordManager.m
//  FinAppletExt
//
//  Created by Haley on 2021/1/21.
//  Copyright © 2021 finogeeks. All rights reserved.
//

#import "FATExtRecordManager.h"
#import "FATExtRecorder.h"
#import "FATExtUtil.h"

#import <FinApplet/FinApplet.h>

static FATExtRecordManager *instance = nil;

@interface FATExtRecordManager () <FATExtRecorderDelegate>

@property (nonatomic, strong) NSMutableDictionary *recordDictionary;

@property (nonatomic, strong) NSMutableDictionary *recorderDict;

@end

@implementation FATExtRecordManager

+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FATExtRecordManager alloc] init];
        instance.recordDictionary = [[NSMutableDictionary alloc] init];
        instance.recorderDict = [[NSMutableDictionary alloc] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_addNotifications];
    }
    return self;
}

#pragma mark - private methods
- (void)p_addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)_clearAudioSession {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:NULL];
    [audioSession setActive:YES error:NULL];
}

#pragma mark - notification handler
- (void)applicationDidEnterBackground:(NSNotification *)notice {
    [self.recorderDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, FATExtRecorder *recorder, BOOL * _Nonnull stop) {
        if (!recorder.isPausing) {
            [self pauseRecordWithData:nil appletId:key];
        }
    }];
}

#pragma mark - new api
- (BOOL)startRecordWithData:(NSDictionary *)data appletId:(NSString *)appletId eventBlock:(void (^)(NSInteger eventType,NSString *eventName, NSDictionary *paramDic,NSDictionary *extDic))eventBlock {
    FATExtRecorder *record = [[FATExtRecorder alloc] init];
    record.delegate = self;
    record.eventCallBack = eventBlock;
    BOOL started = [record startRecordWithDict:data appId:appletId];
    if (started) {
        [self.recorderDict setObject:record forKey:appletId];
        NSDictionary *params = @{@"method" : @"onStart"};

        if (eventBlock) {
            eventBlock(0,@"onRecorderManager",params,nil);
        }
        // 胶囊按钮
        UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
        UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
        if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
            [nav controlCapsuleStateButton:NO state:FATCapsuleButtonStateMicroPhone animate:YES];
        }
        return YES;
    }
    
    return NO;
}

- (BOOL)pauseRecordWithData:(NSDictionary *)data appletId:(NSString *)appletId {
    FATExtRecorder *record = [self.recorderDict objectForKey:appletId];
    if (!record) {
        return NO;
    }
    BOOL result =  [record pauseRecord];
    if (result) {
        if (record.eventCallBack) {
            NSDictionary *params = @{@"method" : @"onPause"};
            record.eventCallBack(0, @"onRecorderManager", params,nil);
        }
        // 胶囊按钮
        UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
        UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
        if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
            [nav controlCapsuleStateButton:YES state:FATCapsuleButtonStateMicroPhone animate:NO];
        }
        return YES;
    }
    
    return NO;
}

- (BOOL)resumeRecordWithData:(NSDictionary *)data appletId:(NSString *)appletId {
    FATExtRecorder *record = [self.recorderDict objectForKey:appletId];
    BOOL result = [record resumeRecord];
    if (result) {
        if (record.eventCallBack) {
            NSDictionary *params = @{@"method" : @"onResume"};
            record.eventCallBack(0, @"onRecorderManager", params,nil);
        }
        // 胶囊按钮
        UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
        UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
        if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
            [nav controlCapsuleStateButton:NO state:FATCapsuleButtonStateMicroPhone animate:YES];
        }
        return YES;
    }
    
    return NO;
}

- (BOOL)stopRecordWithData:(NSDictionary *)data appletId:(NSString *)appletId {
    FATExtRecorder *record = [self.recorderDict objectForKey:appletId];
    [record stopRecord];
    // 胶囊按钮
    UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
    UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
    if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
        [nav controlCapsuleStateButton:YES state:FATCapsuleButtonStateMicroPhone animate:NO];
    }
    return YES;
}

- (BOOL)checkRecordWithMethod:(NSString *)method data:(NSDictionary *)data appletId:(NSString *)appletId {
    FATExtRecorder *recorder = [self.recorderDict objectForKey:appletId];
    if ([method isEqualToString:@"start"]) { // 录制中 或 暂停 时，不能开始
        if (recorder.isRecording || recorder.isPausing) {
            NSDictionary *params = @{
                @"method" : @"onError",
                @"data" : @{@"errMsg" : @"is recording or paused"},
            };
            if (recorder.eventCallBack) {
                recorder.eventCallBack(0, @"onRecorderManager", params,nil);
            }
            return NO;
        }
    } else if ([method isEqualToString:@"pause"]) { // 非录制中状态，不能暂停
        if (![recorder isRecording]) {
            NSDictionary *params = @{
                @"method" : @"onError",
                @"data" : @{@"errMsg" : @"not recording"},
            };
            if (recorder.eventCallBack) {
                recorder.eventCallBack(0, @"onRecorderManager", params,nil);
            }
            return NO;
        }
    } else if ([method isEqualToString:@"resume"]) { // 非暂停状态，不能继续录制
        if (!recorder.isPausing) {
            NSDictionary *params = @{
                @"method" : @"onError",
                @"data" : @{@"errMsg" : @"not paused"},
            };
            if (recorder.eventCallBack) {
                recorder.eventCallBack(0, @"onRecorderManager", params,nil);
            }
            return NO;
        }
    } else if ([method isEqualToString:@"stop"]) { // 非开始状态，不能停止
        if (!recorder.isStarted) {
            NSDictionary *params = @{
                @"method" : @"onError",
                @"data" : @{@"errMsg" : @"recorder not start"},
            };
            if (recorder.eventCallBack) {
                recorder.eventCallBack(0, @"onRecorderManager", params,nil);
            }
            return NO;
        }
    }
    return YES;
}

- (void)sendRecordFrameBufferWithData:(NSDictionary *)data appletId:(NSString *)appletId {
    FATExtRecorder *recorder = [self.recorderDict objectForKey:appletId];
    recorder.frameState = FATFrameStatePrepareToSend;
    if (recorder.frameInfoArray.count == 0) {
        recorder.waitToSendBuffer = YES;
        return;
    }
    
    [self sendFrameDataWithRecorder:recorder withFrameBufferData:nil];
}

- (void)sendFrameDataWithRecorder:(FATExtRecorder *)recorder withFrameBufferData:(NSData *)data {
    // 0.判断是否为分包小程序
    
    recorder.waitToSendBuffer = NO;
    recorder.frameState = FATFrameStateAlreadyWillSend;
    // 1.从文件中取出buffer挂载至jscore上
    NSDictionary *dict = [recorder.frameInfoArray firstObject];
    if (!dict) {
        return;
    }
    
//    NSNumber *frameIndex = dict[@"frameIndex"];
    NSString *frameBufferKey = dict[@"frameBufferKey"];
    NSString *frameBufferPath = dict[@"frameBufferPath"];
    NSNumber *isLastFrame = dict[@"isLastFrame"];
    
    NSData *frameData;
    if (data) {
        frameData = data;
    } else {
        frameData = [NSData dataWithContentsOfFile:frameBufferPath options:0 error:nil];
    }
    Byte *bytes = (Byte *)frameData.bytes;
    NSMutableArray *arrayM = [NSMutableArray array];
    for (int i = 0; i < frameData.length; i++) {
        int number = (int)bytes[i];
        [arrayM addObject:@(number)];
    }
    
    NSDictionary *params = @{
        @"method" : @"onFrameRecorded",
        @"data" : @{
            @"isLastFrame": isLastFrame,
            @"buffer_id": frameBufferKey
        }
    };
    NSDictionary *extDic = @{@"jsContextKey":frameBufferKey,@"jsContextValue":arrayM};
    [recorder.frameInfoArray removeObject:dict];
    if (recorder.eventCallBack) {
        recorder.eventCallBack(0, @"onRecorderManager", params,extDic);
    }
//    [[FATExtCoreEventManager shareInstance] sendToServiceWithAppId:[[FATClient sharedClient] currentApplet].appId eventName:@"onRecorderManager" paramDict:params];
    // 2.将帧信息从数组中删除
    recorder.frameState = FATFrameStateAlreadySent;
}

- (void)checkRecordState {
    FATAppletInfo *appInfo = [[FATClient sharedClient] currentApplet];
    if (!appInfo.appId) {
        return;
    }
    FATExtRecorder *recorder = [self.recorderDict objectForKey:appInfo.appId];
    if ([recorder isRecording]) {
        // 胶囊按钮
        UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
        UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
        if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
            [nav controlCapsuleStateButton:NO state:FATCapsuleButtonStateMicroPhone animate:YES];
        }
    }
}


#pragma mark - FATExtRecorderDelegate
- (void)extRecorder:(FATExtRecorder *)recorder
        onFrameData:(NSData *)frameData
         frameIndex:(NSInteger)frameIndex
        isLastFrame:(BOOL)isLastFrame {
    NSString *frameBufferKey = [recorder.recordFilePath lastPathComponent];
    frameBufferKey = [frameBufferKey stringByDeletingPathExtension];
    frameBufferKey = [frameBufferKey stringByAppendingFormat:@"_%ld", (long)frameIndex];
    
    NSString *frameFileName = [frameBufferKey stringByAppendingPathExtension:recorder.recordFilePath.pathExtension];
    NSString *frameBufferPath = [[recorder.recordFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:frameFileName];
    
    NSDictionary *infoDict = @{@"frameIndex": @(frameIndex),
                               @"isLastFrame": @(isLastFrame),
                               @"frameBufferKey": frameBufferKey,
                               @"frameBufferPath": frameBufferPath
    };
    
    if ([NSThread isMainThread]) {
        [recorder.frameInfoArray addObject:infoDict];
        if (recorder.frameState == FATFrameStatePrepareToSend || recorder.waitToSendBuffer) {
            // 取出录音数据发送
            [self sendFrameDataWithRecorder:recorder withFrameBufferData:frameData];
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [recorder.frameInfoArray addObject:infoDict];
            if (recorder.frameState == FATFrameStatePrepareToSend || recorder.waitToSendBuffer) {
                // 取出录音数据发送
                [self sendFrameDataWithRecorder:recorder withFrameBufferData:frameData];
            }
        });
    }
}

- (void)extRecorder:(FATExtRecorder *)recorder onError:(NSError *)error {
    NSString *msg = error.localizedDescription ? : @"fail";
    NSDictionary *params = @{
        @"method" : @"onError",
        @"data" : @{@"errMsg" : msg},
    };
    if (recorder.eventCallBack) {
        recorder.eventCallBack(0, @"onRecorderManager", params,nil);
    }
}

- (void)extRecorderDidCompletion:(FATExtRecorder *)recorder {
    NSString *filePath = recorder.recordFilePath;    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    float duration = [FATExtUtil durtaionWithFileURL:fileURL];
    long long fileSize = [FATExtUtil fileSizeWithFileURL:fileURL];
    NSString *tempFilePath = [@"finfile://" stringByAppendingString:filePath.lastPathComponent];
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setValue:tempFilePath forKey:@"tempFilePath"];
    [result setValue:@(duration) forKey:@"duration"];
    [result setValue:@(fileSize) forKey:@"fileSize"];

    NSDictionary *params = @{
        @"method" : @"onStop",
        @"data" : result,
    };
    [self.recorderDict removeObjectForKey:recorder.recorderId];
    [self _clearAudioSession];
    if (recorder.eventCallBack) {
        recorder.eventCallBack(0, @"onRecorderManager", params,nil);
    }
}

- (void)extRecorderBeginInterruption:(FATExtRecorder *)recorder {
    NSDictionary *params = @{@"method" : @"onInterruptionBegin"};
    if (recorder.eventCallBack) {
        recorder.eventCallBack(0, @"onRecorderManager", params,nil);
    }
    // 暂停录制
    [self pauseRecordWithData:nil appletId:recorder.recorderId];
}

- (void)extRecorderEndInterruption:(FATExtRecorder *)recorder withOptions:(NSUInteger)flags {
    NSDictionary *params = @{@"method" : @"onInterruptionEnd"};
    if (recorder.eventCallBack) {
        recorder.eventCallBack(0, @"onRecorderManager", params,nil);
    }
}

@end
