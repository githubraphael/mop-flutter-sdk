//
//  FATExtConstant.h
//  FinAppletExt
//
//  Created by Haley on 2021/9/6.
//

#ifndef FATExtPrivateConstant_h
#define FATExtPrivateConstant_h

static NSString *kExtSendToCoreEventNotification = @"kExtSendToCoreEventNotification";

static NSString *FATExtVersionString = @"2.41.3";

typedef NS_ENUM(NSUInteger, FATExtEventType) {
    FATExtEventTypeService, // 发送给service的事件
    FATExtEventTypePage,    // 发送给page层的事件
    FATExtEventTypeView,    // view 操作事件
};

#endif /* FATExtPrivateConstant_h */
