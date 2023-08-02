//
// Copyright (c) 2017, finogeeks.com
// All rights reserved.
//
//
//

#import "FATExtBaseApi.h"

/**
 开始录音。当主动调用wx.stopRecord，或者录音超过1分钟时自动结束录音，返回录音文件的临时文件路径。
 如果前一次录音还在录音 本次录音则不会开始
 */
@interface FATExt_startRecord : FATExtBaseApi

@end
