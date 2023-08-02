//
//  FATExtRecorder.m
//  HLProject
//
//  Created by Haley on 2021/12/28.
//  Copyright © 2021 Haley. All rights reserved.
//

#import "FATExtRecorder.h"
#import "FATExtUtil.h"
#import "lame.h"
#import <FinApplet/FinApplet.h>

#define FATDefaultBufferSize 4096      //设置录音的缓冲区默认大小为4096,实际会小于或等于4096,需要处理小于4096的情况
#define QUEUE_BUFFER_SIZE 3      //输出音频队列缓冲个数


@interface FATExtRecorder ()
{
    AudioQueueRef audioQRef;       //音频队列对象指针
    AudioStreamBasicDescription inputDescription;   //音频流配置
    AudioStreamBasicDescription outputDescription;   //音频流配置
    AudioQueueBufferRef audioBuffers[QUEUE_BUFFER_SIZE];  //音频流缓冲区对象
    
    AudioConverterRef _encodeConvertRef;
    
    lame_t lame;
    FILE *mp3;
    
    int          pcm_buffer_size;
    uint8_t      pcm_buffer[FATDefaultBufferSize*2];
}

@property (nonatomic, assign) AudioFileID recordFileID;   //音频文件标识  用于关联音频文件
@property (nonatomic, assign) SInt64 recordPacketNum;

@property (nonatomic, copy) NSString *recorderId;

// 录音的声道数
@property (nonatomic, assign) UInt32 mChannelsPerFrame;
// 录音采样率
@property (nonatomic, assign) UInt32 mSampleRate;
// 编码码率
@property (nonatomic, assign) UInt32 encodeBitRate;
// 录制的最大时长
@property (nonatomic, assign) int duration;
// 录音文件格式
@property (nonatomic, copy) NSString *format;
@property (nonatomic, assign) long long frameSize;
@property (nonatomic, assign) BOOL shouldFrameCallback;

@property (nonatomic, assign) NSInteger currentBufferIndex;
// 当前这一帧的buffer数据
@property (nonatomic, strong) NSMutableData *currentFrameData;
@property (nonatomic, assign) long long currentFrameOffset;

@end

@implementation FATExtRecorder

void FATAudioInputCallbackHandler(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc) {
    
    FATExtRecorder *recorder = (__bridge FATExtRecorder *)(inUserData);
    [recorder processAudioBuffer:inBuffer inStartTime:inStartTime inNumPackets:inNumPackets inPacketDesc:inPacketDesc audioQueue:inAQ];
}

OSStatus FATAudioConverterComplexInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
    
    FATExtRecorder *recorder = (__bridge FATExtRecorder *)(inUserData);
    
    BOOL result = [recorder handleConverterDataProcWithBufferList:ioData];
    if (result) {
        return noErr;
    }
    
    return -1;
}

#pragma mark - override
- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_addNotifications];
    }
    return self;
}

- (void)dealloc {
//    NSLog(@"FATExtRecorder---dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    AudioQueueDispose(audioQRef, true);
}

- (void)handleInterruption:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        if ([self.delegate respondsToSelector:@selector(extRecorderBeginInterruption:)]) {
            [self.delegate extRecorderBeginInterruption:self];
        }
    } else {
        AVAudioSessionInterruptionOptions options = [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            //Handle Resume
        }
        if ([self.delegate respondsToSelector:@selector(extRecorderEndInterruption:withOptions:)]) {
            [self.delegate extRecorderEndInterruption:self withOptions:options];
        }
    }
}

- (BOOL)startRecordWithDict:(NSDictionary *)dict appId:(NSString *)appId {
    self.currentBufferIndex = 0;
    self.currentFrameOffset = 0;
    self.currentFrameData = [[NSMutableData alloc] init];
    self.frameState = FATFrameStatePrepareToSend;
    self.frameInfoArray = [NSMutableArray array];
    
    memset(pcm_buffer, 0, pcm_buffer_size);
    pcm_buffer_size = 0;
    
    self.recorderId = appId;
    // 1.配置录音的参数
    // 录音的音频输入源
    NSString *audioSource;
    if (!audioSource || ![audioSource isKindOfClass:[NSString class]]) {
        audioSource = @"auto";
    } else {
        audioSource = dict[@"audioSource"];
    }
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSource isEqualToString:@"buildInMic"]) {
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:NULL];
    } else if ([audioSource isEqualToString:@"headsetMic"]) {
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:NULL];
    } else {
        if (@available(iOS 10.0, *)) {
            // 这里通过计算，找不到与运算后为45的结果（45为微信的值）
//            NSUInteger options = AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowAirPlay;
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeDefault options:45 error:NULL];
        } else {
            NSUInteger options = AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth;
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options error:NULL];
        }
    }
    [audioSession setActive:YES error:NULL];
    
    // 1.1 格式
    NSString *format = [self _format:dict];
    
    self.format = format;
    AudioFormatID formatID = [self _formatIDWithFormat:format];
    inputDescription.mFormatID = formatID;
    
    // 1.2.录音通道数
    NSString *numberOfChannelsString = dict[@"numberOfChannels"];
    if (![self _isValidWithNumberOfChannelsString:numberOfChannelsString]) {
        if ([self.delegate respondsToSelector:@selector(extRecorder:onError:)]) {
            NSError *error = [NSError errorWithDomain:@"FATExtRecorder" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"operateRecorder:fail channel error"}];
            [self.delegate extRecorder:self onError:error];
        }
        return NO;
    }
    
    NSNumber *numberOfChannelsNub = [NSNumber numberWithInt:[numberOfChannelsString intValue]];
    if (numberOfChannelsString == nil) {
        numberOfChannelsNub = @(2);
    }
    if ([format isEqualToString:@"aac"]) {
        // aac 格式双声道有杂音，暂时只支持单声道
        numberOfChannelsNub = @(1);
    }
    
    inputDescription.mChannelsPerFrame = [numberOfChannelsNub intValue];
    self.mChannelsPerFrame = [numberOfChannelsNub intValue];
    
    // 1.3.采样率
    NSString *sampleRateString = dict[@"sampleRate"];
    NSNumber *sampleRateNub;
    if (sampleRateString == nil || ![sampleRateString isKindOfClass:[NSString class]]) {
        sampleRateNub = @(8000);
    } else {
        sampleRateNub = [NSNumber numberWithInt:[sampleRateString intValue]];
    }
    inputDescription.mSampleRate = [sampleRateNub floatValue];
    self.mSampleRate = inputDescription.mSampleRate;
    
    // 1.4.编码比特率
    NSString *encodeBitRateString = dict[@"encodeBitRate"];
    NSNumber *encodeBitRateNub;
    if (encodeBitRateString == nil || ![encodeBitRateString isKindOfClass:[NSString class]]) {
        encodeBitRateNub = @(48000);
    } else {
        encodeBitRateNub = [NSNumber numberWithInt:[encodeBitRateString intValue]];
    }
    self.encodeBitRate = [encodeBitRateNub floatValue];
    
    NSString *durationString = dict[@"duration"];
    NSNumber *durationNub;
    if (durationString == nil || ![durationString isKindOfClass:[NSString class]]) {
        durationNub = @(60000);
    } else {
        durationNub = [NSNumber numberWithInt:[durationString intValue]];
    }
    
    if ([durationNub intValue] <= 0) {
        durationNub = @(60000);
    }
    
    if ([durationNub intValue] > 600000) {
        durationNub = @(600000);
    }
    
    self.duration = [durationNub intValue];
    
    // 编码格式
    inputDescription.mFormatID = kAudioFormatLinearPCM;
    inputDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    
    inputDescription.mBitsPerChannel = 16;
    // 每帧的字节数
    inputDescription.mBytesPerFrame = (inputDescription.mBitsPerChannel / 8) * inputDescription.mChannelsPerFrame;
    // 每个包的字节数
    inputDescription.mBytesPerPacket = inputDescription.mBytesPerFrame;
    // 每个包的帧数
    inputDescription.mFramesPerPacket = 1;
    
    // 2. 生成文件名
    NSString *fileName = [self _fileNameWithFormat:format];
    NSString *filePath = [[FATExtUtil tmpDirWithAppletId:appId] stringByAppendingPathComponent:fileName];
    self.recordFilePath = filePath;
    
    if ([format isEqualToString:@"mp3"]) {
        mp3 = fopen([self.recordFilePath cStringUsingEncoding:1], "wb");
        lame = lame_init();
        //采样率跟原音频参数设置一致
        lame_set_in_samplerate(lame, inputDescription.mSampleRate);
        // 通道数跟原音频参数设置一致，不设置默认为双通道
        lame_set_num_channels(lame, inputDescription.mChannelsPerFrame);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
    } else if ([format isEqualToString:@"aac"]) {
        NSError *error;
        if (![self _createConverter:&error]) {
            if ([self.delegate respondsToSelector:@selector(extRecorder:onError:)]) {
                [self.delegate extRecorder:self onError:error];
            }
            return NO;
        }
        [self copyEncoderCookieToFile];
    }
    
    OSStatus status = AudioQueueNewInput(&inputDescription, FATAudioInputCallbackHandler, (__bridge void *)(self), NULL, NULL, 0, &audioQRef);
    if ( status != kAudioSessionNoError ) {
        if ([self.delegate respondsToSelector:@selector(extRecorder:onError:)]) {
            NSError *error = [NSError errorWithDomain:@"FATExtRecorder" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"AudioQueueNewInput fail"}];
            [self.delegate extRecorder:self onError:error];
        }
        return NO;
    }
    
    // 1.5 frameSize
    NSString *frameSizeString = dict[@"frameSize"];
    if (![frameSizeString isKindOfClass:[NSString class]]) {
        frameSizeString = nil;
    }
    //设置的缓冲区有多大，那么在回调函数的时候得到的inbuffer的大小就是多大。callBack不足的时候，需要拼接，等待满足frameSize
    long long bufferByteSize = FATDefaultBufferSize;
    if ([frameSizeString floatValue]> 0.00 && [self _canCallbackFormat:format]) {
        self.shouldFrameCallback = YES;
        self.frameSize = (long long)[frameSizeString floatValue] * 1024;
    }
    
    if ([format isEqualToString:@"aac"]) {
        // aac格式需要1024帧，每帧2字节
        bufferByteSize = 1024 * 2 * self.mChannelsPerFrame;
    }
    
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++){
        AudioQueueAllocateBuffer(audioQRef, bufferByteSize, &audioBuffers[i]);
        AudioQueueEnqueueBuffer(audioQRef, audioBuffers[i], 0, NULL);
    }
    
    CFURLRef url = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)self.recordFilePath, NULL);
    // 创建音频文件
    if ([format isEqualToString:@"aac"]) {
        AudioFileCreateWithURL(url, kAudioFileCAFType, &outputDescription, kAudioFileFlags_EraseFile, &_recordFileID);
    } else {
        AudioFileCreateWithURL(url, kAudioFileCAFType, &inputDescription, kAudioFileFlags_EraseFile, &_recordFileID);
    }
    
    CFRelease(url);
    
    self.recordPacketNum = 0;
    status = AudioQueueStart(audioQRef, NULL);
    if (status != kAudioSessionNoError) {
        if ([self.delegate respondsToSelector:@selector(extRecorder:onError:)]) {
            NSError *error = [NSError errorWithDomain:@"FATExtRecorder" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"AudioQueueStart fail"}];
            [self.delegate extRecorder:self onError:error];
        }
        AudioQueueStop(audioQRef, NULL);
        return NO;
    }
    self.isStarted = YES;
    self.isRecording = YES;
    
    return YES;
}

- (BOOL)pauseRecord {
    OSStatus status = AudioQueuePause(audioQRef);
    if (status != kAudioSessionNoError) {
        if ([self.delegate respondsToSelector:@selector(extRecorder:onError:)]) {
            NSError *error = [NSError errorWithDomain:@"FATExtRecorder" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"pause fail"}];
            [self.delegate extRecorder:self onError:error];
        }
        return NO;
    }
    self.isRecording = NO;
    self.isPausing = YES;
    return YES;
}

- (BOOL)resumeRecord {
    OSStatus status = AudioQueueStart(audioQRef, NULL);
    if (status != kAudioSessionNoError) {
        if ([self.delegate respondsToSelector:@selector(extRecorder:onError:)]) {
            NSError *error = [NSError errorWithDomain:@"FATExtRecorder" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"resume fail"}];
            [self.delegate extRecorder:self onError:error];
        }
        return NO;
    }
    self.isRecording = YES;
    self.isPausing = NO;
    return YES;
}

- (BOOL)stopRecord {
    if (self.isRecording) {
        self.isRecording = NO;
    }
    self.isStarted = NO;
    // 停止录音队列
    AudioQueueStop(audioQRef, true);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AudioFileClose(_recordFileID);
        [self didEndRecord];
    });
    
    return YES;
}

#pragma mark - private
- (void)processAudioBuffer:(AudioQueueBufferRef)inBuffer inStartTime:(AudioTimeStamp *)inStartTime inNumPackets:(UInt32)inNumPackets inPacketDesc:(AudioStreamPacketDescription *)inPacketDesc audioQueue:(AudioQueueRef)audioQueueRef
{
    const int audioSize = inBuffer->mAudioDataByteSize;
//    NSLog(@"processAudioBuffer---inNumPackets:%d, size:%d", inNumPackets, audioSize);
    if (inNumPackets > 0) {
        if ([self.format isEqualToString:@"mp3"]) {
            unsigned char mp3_buffer[audioSize];
            // 说法1：因为录音数据是char *类型的，一个char占一个字节。而这里要传的数据是short *类型的，一个short占2个字节
            // 说法2：每packet 有 1 帧; 单声道： 每 帧2 Bytes; 双声道： 每帧 4 Bytes。
            // 所以 单声道 nsamples = inBuffer->mAudioDataByteSize / 2;
            // 双声道 nsamples = inBuffer->mAudioDataByteSize / 4;
            // 结果 nsamples 正好等于 inNumPackets;
            int nsamples = inNumPackets;
            /**
             双声道必须要使用lame_encode_buffer_interleaved这个函数
             lame_encode_buffer             //录音数据单声道16位整形用这个方法
             lame_encode_buffer_interleaved //录音数据双声道交错用这个方法
             lame_encode_buffer_float       //录音数据采样深度32位浮点型用这个方法
             */
            int recvLen;
            if (self.mChannelsPerFrame == 1) {
                // 单声道音频转码
                recvLen = lame_encode_buffer(lame, inBuffer->mAudioData, NULL, nsamples, mp3_buffer, audioSize);
            } else {
                recvLen = lame_encode_buffer_interleaved(lame, inBuffer->mAudioData, nsamples, mp3_buffer, audioSize);
            }
            // 写入文件
            fwrite(mp3_buffer, recvLen, 1, mp3);
            if (self.shouldFrameCallback) {
                [self.currentFrameData appendBytes:mp3_buffer length:recvLen];
            }
//            NSLog(@"%d", recvLen);
        } else if ([self.format isEqualToString:@"pcm"]) {
            // 非MP3格式直接写入文件
            void *bufferData = inBuffer->mAudioData;
            UInt32 buffersize = inBuffer->mAudioDataByteSize;
            if (self.shouldFrameCallback) {
                [self.currentFrameData appendBytes:bufferData length:buffersize];
            }
            AudioFileWritePackets(self.recordFileID, FALSE, audioSize, inPacketDesc, self.recordPacketNum, &inNumPackets, inBuffer->mAudioData);
            self.recordPacketNum += inNumPackets;
        } else if ([self.format isEqualToString:@"aac"]) {
            memcpy(pcm_buffer + pcm_buffer_size, inBuffer->mAudioData, inBuffer->mAudioDataByteSize);
            pcm_buffer_size = pcm_buffer_size + inBuffer->mAudioDataByteSize;
            
            long long willEncodePCMBufferSize = 1024 * 2 * self.mChannelsPerFrame;
            if (pcm_buffer_size >= willEncodePCMBufferSize) {
                AudioBufferList *bufferList = [self convertedAACBufferListWith:inBuffer];
                
                memcpy(pcm_buffer, pcm_buffer + willEncodePCMBufferSize, pcm_buffer_size - willEncodePCMBufferSize);
                pcm_buffer_size = pcm_buffer_size - willEncodePCMBufferSize;
                
                void *bufferData = inBuffer->mAudioData;
                UInt32 buffersize = inBuffer->mAudioDataByteSize;
                
                if (self.shouldFrameCallback) {
                    [self.currentFrameData appendBytes:bufferData length:buffersize];
                }
                // free memory
                if (bufferList) {
                    free(bufferList->mBuffers[0].mData);
                    free(bufferList);
                }
            }
        } else if ([self.format isEqualToString:@"wav"]) {
            // 新增wav格式的音频。
            void *bufferData = inBuffer->mAudioData;
            UInt32 buffersize = inBuffer->mAudioDataByteSize;
            AudioFileWritePackets(self.recordFileID, FALSE, audioSize, inPacketDesc, self.recordPacketNum, &inNumPackets, inBuffer->mAudioData);
            self.recordPacketNum += inNumPackets;
        }
        
        if (self.shouldFrameCallback) {
            if ([self.format isEqualToString:@"pcm"]) {
                long long fileSize = [self _getFileSize:self.recordFilePath];
                long long currentFrameSize;
                if (self.currentBufferIndex == 0) {
                    currentFrameSize = fileSize - FATDefaultBufferSize;
                    self.currentFrameOffset = FATDefaultBufferSize;
                } else {
                    currentFrameSize = fileSize - self.currentFrameOffset;
                }
                
                if (fileSize > self.frameSize) {
                    if ([self.delegate respondsToSelector:@selector(extRecorder:onFrameData:frameIndex:isLastFrame:)]) {
                        [self.delegate extRecorder:self onFrameData:self.currentFrameData frameIndex:self.currentBufferIndex isLastFrame:NO];
                    }
                    self.currentFrameData = [[NSMutableData alloc] init];
                    self.currentBufferIndex++;
                }
                
            } else if ([self.format isEqualToString:@"mp3"]) {
                long long fileSize = [self _getFileSize:self.recordFilePath];
                long long currentFrameSize;
                if (self.currentBufferIndex == 0) {
                    currentFrameSize = fileSize - FATDefaultBufferSize;
                    self.currentFrameOffset = FATDefaultBufferSize;
                } else {
                    currentFrameSize = fileSize - self.currentFrameOffset;
                }
                
                if (currentFrameSize > self.frameSize) {
                    // 满足一帧
                    NSString *frameFilePath = [self.recordFilePath stringByDeletingPathExtension];
                    frameFilePath = [frameFilePath stringByAppendingFormat:@"_%d", self.currentBufferIndex];
                    frameFilePath = [frameFilePath stringByAppendingPathExtension:self.recordFilePath.pathExtension];
                    BOOL result = [self.currentFrameData writeToFile:frameFilePath atomically:YES];
//                    NSLog(@"写入文件:%@, 结果:%d",frameFilePath.lastPathComponent, result);
                    
                    if ([self.delegate respondsToSelector:@selector(extRecorder:onFrameData:frameIndex:isLastFrame:)]) {
                        [self.delegate extRecorder:self onFrameData:self.currentFrameData frameIndex:self.currentBufferIndex isLastFrame:NO];
                    }
                    
                    self.currentFrameData = [[NSMutableData alloc] init];
                    self.currentFrameOffset += currentFrameSize;
                    self.currentBufferIndex++;
                }
            } else if ([self.format isEqualToString:@"aac"]) {
                long long fileSize = [self _getFileSize:self.recordFilePath];
//                NSLog(@"fileSize:%lld", fileSize);
                
                long long currentFrameSize;
                if (self.currentBufferIndex == 0) {
                    currentFrameSize = fileSize - FATDefaultBufferSize;
                    self.currentFrameOffset = FATDefaultBufferSize;
                } else {
                    currentFrameSize = fileSize - self.currentFrameOffset;
                }
                
                if (currentFrameSize > self.frameSize) {
                    // 满足一帧
//                    NSLog(@"currentFrameSize:%d", currentFrameSize);
                    NSString *frameFilePath = [self.recordFilePath stringByDeletingPathExtension];
                    frameFilePath = [frameFilePath stringByAppendingFormat:@"_%d", self.currentBufferIndex];
                    frameFilePath = [frameFilePath stringByAppendingPathExtension:self.recordFilePath.pathExtension];
                    BOOL result = [self.currentFrameData writeToFile:frameFilePath atomically:YES];
//                    NSLog(@"写入文件:%@, 结果:%d",frameFilePath.lastPathComponent, result);
                    
                    if ([self.delegate respondsToSelector:@selector(extRecorder:onFrameData:frameIndex:isLastFrame:)]) {
                        [self.delegate extRecorder:self onFrameData:self.currentFrameData frameIndex:self.currentBufferIndex isLastFrame:NO];
                    }
                    
                    self.currentFrameData = [[NSMutableData alloc] init];
                    self.currentFrameOffset += currentFrameSize;
                    self.currentBufferIndex++;
                }
            }
        }
    }
    
    NSTimeInterval recordDuration = inStartTime->mSampleTime / self.mSampleRate * 1000.0;
    if (recordDuration >= self.duration) {
        if (self.isRecording) {
            [self stopRecord];
        }
        return;
    }
    
    if (self.isRecording || self.isPausing) {
       // 将缓冲器重新放入缓冲队列，以便重复使用该缓冲器
        AudioQueueEnqueueBuffer(audioQueueRef, inBuffer, 0, NULL);
    }
}

- (BOOL)handleConverterDataProcWithBufferList:(AudioBufferList *)bufferList
{
    if ([self.format isEqualToString:@"aac"]) {
        bufferList->mBuffers[0].mData = pcm_buffer;
        bufferList->mBuffers[0].mNumberChannels = self.mChannelsPerFrame;
        bufferList->mBuffers[0].mDataByteSize = 1024 * 2 * self.mChannelsPerFrame;
        
        return YES;
    }
    
    return NO;
}

- (void)didEndRecord {
    if ([self.format isEqualToString:@"mp3"]) {
        // 写入VBR 头文件, 否则录音的时长不准
        lame_mp3_tags_fid(lame, mp3);
        lame_close(lame);
        fclose(mp3);
    }
    
    if (self.currentFrameData.length > 0) {
        NSString *frameFilePath = [self.recordFilePath stringByDeletingPathExtension];
        frameFilePath = [frameFilePath stringByAppendingFormat:@"_%d", self.currentBufferIndex];
        frameFilePath = [frameFilePath stringByAppendingPathExtension:self.recordFilePath.pathExtension];
        BOOL result = [self.currentFrameData writeToFile:frameFilePath atomically:YES];
//        NSLog(@"Last写入文件:%@, 结果:%d",frameFilePath.lastPathComponent, result);
        
        if ([self.delegate respondsToSelector:@selector(extRecorder:onFrameData:frameIndex:isLastFrame:)]) {
            [self.delegate extRecorder:self onFrameData:self.currentFrameData frameIndex:self.currentBufferIndex isLastFrame:YES];
        }
        
        self.currentFrameData = nil;
        self.currentFrameOffset = 0;
        self.currentBufferIndex = 0;
    }
    
    if ([self.delegate respondsToSelector:@selector(extRecorderDidCompletion:)]) {
        [self.delegate extRecorderDidCompletion:self];
    }
    
    // 胶囊按钮(不管什么原因导致的结束录音，都在这里面恢复胶囊按钮的状态)
    UIViewController *vc = [[UIApplication sharedApplication] fat_topViewController];
    UINavigationController<FATCapsuleViewProtocol> *nav = (UINavigationController<FATCapsuleViewProtocol> *)vc.navigationController;
    if ([nav respondsToSelector:@selector(controlCapsuleStateButton:state:animate:)]) {
        [nav controlCapsuleStateButton:YES state:FATCapsuleButtonStateMicroPhone animate:NO];
    }
}

- (void)p_addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
}

#pragma mark - tool method
- (NSString *)_format:(NSDictionary *)data {
    NSString *format = data[@"format"];
    if (!format || ![format isKindOfClass:[NSString class]]) {
        format = @"aac";
    }
    format = [format lowercaseString];
    NSArray *validFormats = @[@"mp3", @"aac", @"wav", @"pcm"];
    if (![validFormats containsObject:format]) {
        return @"aac";
    }
    
    return format;
}

- (AudioFormatID)_formatIDWithFormat:(NSString *)format {
    return kAudioFormatLinearPCM;
}

- (BOOL)_isValidWithNumberOfChannelsString:(NSString *)numberOfChannelsString {
    if (!numberOfChannelsString) {
        return YES;
    }
    
    if (![numberOfChannelsString isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    if ([numberOfChannelsString isEqualToString:@"1"] || [numberOfChannelsString isEqualToString:@"2"]) {
        return YES;
    }
    
    return NO;
}

- (NSString *)_fileNameWithFormat:(NSString *)format {
    NSString *currentDt = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    NSData *data = [currentDt dataUsingEncoding:NSUTF8StringEncoding];
    NSString *nameMD5 = [[FATExtUtil fat_md5WithBytes:(char *)[data bytes] length:data.length] lowercaseString];
    NSString *extensionName = [self _extensionNameWithFormat:format];
    NSString *fileName = [NSString stringWithFormat:@"tmp_%@%@", nameMD5, extensionName];
    return fileName;
}

- (NSString *)_extensionNameWithFormat:(NSString *)format {
//    if ([format isEqualToString:@"aac"]) {
//        return @".m4a";
//    }
    if ([format isEqualToString:@"pcm"]) {
        return @".caf";
    }
    
    NSString *ext = [NSString stringWithFormat:@".%@", format];
    return ext;
}

- (BOOL)_canCallbackFormat:(NSString *)format
{
    if ([format isEqualToString:@"mp3"]) {
        return YES;
    }
    if ([format isEqualToString:@"pcm"]) {
        return YES;
    }
    if ([format isEqualToString:@"aac"]) {
        return YES;
    }
    
    return NO;
}

- (long long)_getFileSize:(NSString *)path
{
    NSFileManager *filemanager = [NSFileManager defaultManager];
    if (![filemanager fileExistsAtPath:path]) {
        return 0;
    }
    
    NSDictionary *attributes = [filemanager attributesOfItemAtPath:path error:nil];
    NSNumber *theFileSize = [attributes objectForKey:NSFileSize];
    return [theFileSize longLongValue];
}

- (BOOL)_createConverter:(NSError **)aError {
    // 此处目标格式其他参数均为默认，系统会自动计算，否则无法进入encodeConverterComplexInputDataProc回调
    AudioStreamBasicDescription sourceDes = inputDescription; // 原始格式
    AudioStreamBasicDescription targetDes;              // 转码后格式
    
    // 设置目标格式及基本信息
    memset(&targetDes, 0, sizeof(targetDes));
    targetDes.mFormatID           = kAudioFormatMPEG4AAC;
    targetDes.mSampleRate         = inputDescription.mSampleRate ;
    targetDes.mChannelsPerFrame   = inputDescription.mChannelsPerFrame;
    targetDes.mFramesPerPacket    = 1024; // 采集的为AAC需要将targetDes.mFramesPerPacket设置为1024，AAC软编码需要喂给转换器1024个样点才开始编码，这与回调函数中inNumPackets有关，不可随意更改
    
    OSStatus status = 0;
    UInt32 targetSize = sizeof(targetDes);
    status = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &targetSize, &targetDes);
    
    memset(&outputDescription, 0, sizeof(outputDescription));
    memcpy(&outputDescription, &targetDes, targetSize);
    
    // 选择软件编码
    AudioClassDescription audioClassDes;
    status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                        sizeof(targetDes.mFormatID),
                                        &targetDes.mFormatID,
                                        &targetSize);
    
    UInt32 numEncoders = targetSize/sizeof(AudioClassDescription);
    AudioClassDescription audioClassArr[numEncoders];
    AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                           sizeof(targetDes.mFormatID),
                           &targetDes.mFormatID,
                           &targetSize,
                           audioClassArr);
    
    for (int i = 0; i < numEncoders; i++) {
        if (audioClassArr[i].mSubType == kAudioFormatMPEG4AAC && audioClassArr[i].mManufacturer == kAppleSoftwareAudioCodecManufacturer) {
            memcpy(&audioClassDes, &audioClassArr[i], sizeof(AudioClassDescription));
            break;
        }
    }
    
    status = AudioConverterNewSpecific(&sourceDes, &targetDes, 1, &audioClassDes, &_encodeConvertRef);
    
    if (status != noErr) {
        *aError = [NSError errorWithDomain:@"FATExtRecorder" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"create converter fail"}];
//        NSLog(@"Error : New convertRef failed");
        return NO;
    }
    
    targetSize = sizeof(sourceDes);
    status = AudioConverterGetProperty(_encodeConvertRef, kAudioConverterCurrentInputStreamDescription, &targetSize, &sourceDes);
    
    targetSize = sizeof(targetDes);
    status = AudioConverterGetProperty(_encodeConvertRef, kAudioConverterCurrentOutputStreamDescription, &targetSize, &targetDes);
    
    // 设置码率，需要和采样率对应
    UInt32 bitRate  = self.encodeBitRate;
    targetSize      = sizeof(bitRate);
    status          = AudioConverterSetProperty(_encodeConvertRef,
                                                kAudioConverterEncodeBitRate,
                                                targetSize, &bitRate);
    if (status != noErr) {
        *aError = [NSError errorWithDomain:@"FATExtRecorder" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"encodeBitRate not applicable"}];
//        NSLog(@"Error : set encodeBitRate failed");
        return NO;
    }
    
    return YES;
}

- (void)copyEncoderCookieToFile {
    UInt32 cookieSize = 0;
    OSStatus status = AudioConverterGetPropertyInfo(_encodeConvertRef, kAudioConverterCompressionMagicCookie, &cookieSize, NULL);
    
    if (status != noErr || cookieSize == 0) {
        return;
    }
    
    char *cookie = (char *)malloc(cookieSize * sizeof(char));
    status = AudioConverterGetProperty(_encodeConvertRef, kAudioConverterCompressionMagicCookie, &cookieSize, cookie);

    if (status == noErr) {
        status = AudioFileSetProperty(_recordFileID, kAudioFilePropertyMagicCookieData, cookieSize, cookie);
        if (status == noErr) {
            UInt32 willEatTheCookie = false;
            status = AudioFileGetPropertyInfo(_recordFileID, kAudioFilePropertyMagicCookieData, NULL, &willEatTheCookie);
            printf("Writing magic cookie to destination file: %u\n   cookie:%d \n", (unsigned int)cookieSize, willEatTheCookie);
        } else {
            printf("Even though some formats have cookies, some files don't take them and that's OK\n");
        }
    } else {
        printf("Could not Get kAudioConverterCompressionMagicCookie from Audio Converter!\n");
    }
    
    free(cookie);
}

- (AudioBufferList *)convertedAACBufferListWith:(AudioQueueBufferRef)inBuffer
{
    UInt32 maxPacketSize = 0;
    UInt32 size = sizeof(maxPacketSize);
    OSStatus status;
    
    status = AudioConverterGetProperty(_encodeConvertRef,
                                       kAudioConverterPropertyMaximumOutputPacketSize,
                                       &size,
                                       &maxPacketSize);

    AudioBufferList *bufferList             = (AudioBufferList *)malloc(sizeof(AudioBufferList));
    bufferList->mNumberBuffers              = 1;
    bufferList->mBuffers[0].mNumberChannels = self.mChannelsPerFrame;
    bufferList->mBuffers[0].mData           = malloc(maxPacketSize);
    bufferList->mBuffers[0].mDataByteSize   = 1024 * 2 * self.mChannelsPerFrame;
    
    UInt32 inNumPackets = 1;
    AudioStreamPacketDescription outputPacketDescriptions;
    status = AudioConverterFillComplexBuffer(_encodeConvertRef,
                                             FATAudioConverterComplexInputDataProc,
                                             (__bridge void * _Nullable)(self),
                                             &inNumPackets,
                                             bufferList,
                                             &outputPacketDescriptions);
    
    if (status != noErr) {
        free(bufferList->mBuffers[0].mData);
        free(bufferList);
        return nil;
    }
    
    status = AudioFileWritePackets(self.recordFileID,
                                    FALSE,
                                    bufferList->mBuffers[0].mDataByteSize,
                                    &outputPacketDescriptions,
                                    self.recordPacketNum,
                                    &inNumPackets,
                                    bufferList->mBuffers[0].mData);
    if (status == noErr) {
        self.recordPacketNum += inNumPackets;  // 用于记录起始位置
    } else {
//        NSLog(@"数据写入失败");
    }
    
    return  bufferList;
}

@end
