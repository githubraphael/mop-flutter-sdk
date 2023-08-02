//
//  FATExtAVManager.m
//  FinAppletExt
//
//  Created by Haley on 2020/8/14.
//  Copyright © 2020 finogeeks. All rights reserved.
//

#import "FATExtAVManager.h"
#import "FATExtFileManager.h"

#import <AVFoundation/AVFoundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <FinApplet/FinApplet.h>

@interface FATExtAVManager () <AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;

@property (nonatomic, copy) FATExtAVSuccess recordSuccess;
@property (nonatomic, copy) FATExtAVFail recordFail;

@end

@implementation FATExtAVManager

+ (instancetype)sharedManager {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[FATExtAVManager alloc] init];
        [_sharedInstance add_notifications];
    });

    return _sharedInstance;
}

- (void)add_notifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appletPageDisappear:) name:kFATPageDidDisappearNotification object:nil];
}

- (void)appletPageDisappear:(NSNotification *)notification
{
    if (self.recorder) {
        [self.recorder pause];
        if (self.recordFail) {
            self.recordFail(@"fail");
        }
        [self.recorder deleteRecording];
        self.recorder = nil;
        
        // 胶囊按钮
        UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
        UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
        if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
            [nav controlCapsuleStateButton:YES state:FATCapsuleButtonStateMicroPhone animate:NO];
        }
    }
}

/**
 开始录音

 @param success 成功回调
 @param fail 失败回调
 */
- (void)startRecordWithSuccess:(FATExtAVSuccess)success fail:(FATExtAVFail)fail {
    if ([self.recorder isRecording]) {
        fail(@"正在录音中...");
        return;
    }

    self.recordSuccess = success;
    self.recordFail = fail;

    self.recorder = [self createAudioRecord];

    [self.recorder prepareToRecord];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:NULL];
    [audioSession setActive:YES error:NULL];
    [self.recorder recordForDuration:60];
    
    // 胶囊按钮
    UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
    UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
    if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
        [nav controlCapsuleStateButton:NO state:FATCapsuleButtonStateMicroPhone animate:YES];
    }
}

/**
 停止录音
 */
- (void)stopRecord {
    if (self.recorder) {
        [self.recorder stop];
        self.recorder = nil;
        
        // 胶囊按钮
        UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
        UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
        if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
            [nav controlCapsuleStateButton:YES state:FATCapsuleButtonStateMicroPhone animate:NO];
        }
    }
}

- (void)checkRecordState {
    if ([self.recorder isRecording]) {
        // 胶囊按钮
        UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
        UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
        if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
            [nav controlCapsuleStateButton:NO state:FATCapsuleButtonStateMicroPhone animate:YES];
        }
    }
}

#pragma mark - private method

- (AVAudioRecorder *)createAudioRecord {
    // 使用此配置 录制1分钟大小200KB左右
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                               [NSNumber numberWithFloat:16000.0], AVSampleRateKey,
                                               [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                               nil];

    // 使用当前时间戳的md5作为文件名
    NSString *currentDt = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    NSData *data = [currentDt dataUsingEncoding:NSUTF8StringEncoding];
    NSString *nameMD5 = [self fat_md5WithBytes:(char *)[data bytes] length:data.length];
    NSString *fileName = [NSString stringWithFormat:@"tmp_%@.m4a", nameMD5];
    NSString *filePath = [[self tmpDir] stringByAppendingPathComponent:fileName];
    AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:filePath] settings:settings error:nil];
    recorder.delegate = self;

    return recorder;
}

- (NSString *)tmpDir {
    FATAppletInfo *appInfo = [[FATClient sharedClient] currentApplet];
    NSString *cacheDir = [FATExtFileManager appTempDirPath:appInfo.appId];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL flag = YES;
    if (![fileManager fileExistsAtPath:cacheDir isDirectory:&flag]) {
        [fileManager createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return cacheDir;
}

- (NSString *)fat_md5WithBytes:(char *)bytes length:(NSUInteger)length {
    unsigned char result[16];
    CC_MD5(bytes, (CC_LONG)length, result);
    return [NSString stringWithFormat:
                         @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                         result[0], result[1], result[2], result[3],
                         result[4], result[5], result[6], result[7],
                         result[8], result[9], result[10], result[11],
                         result[12], result[13], result[14], result[15]];
}

#pragma mark - AVAudioRecord Delegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSString *filePath = recorder.url.lastPathComponent;
    if (flag) {
        if (self.recordSuccess) {
            self.recordSuccess([@"finfile://" stringByAppendingString:filePath]);
        }
    } else {
        [recorder deleteRecording];
        if (self.recordFail) {
            self.recordFail(@"fail");
        }
    }

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:NULL];
    [audioSession setActive:YES error:NULL];

    self.recorder = nil;
    self.recordSuccess = nil;
    self.recordFail = nil;
    
    // 胶囊按钮
    UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
    UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
    if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
        [nav controlCapsuleStateButton:YES state:FATCapsuleButtonStateMicroPhone animate:NO];
    }
}

@end
