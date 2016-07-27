//
//  RemindAvManager.h
//  ChatDemo-UI3.0
//
//  Created by WYZ on 16/7/22.
//  Copyright © 2016年 WYZ. All rights reserved.
//

#import <Foundation/Foundation.h>

//cmd消息中ext特殊字段
#define CALL_PARTY_USER                     @"call_party_user"  //主叫方
#define CALLED_PARTY_USER                   @"called_party_user"  //被叫方
#define CALL_TYPE                           @"call_type"  //呼叫类型  int类型，0是音频，1是视频

@protocol RemindAvDelegate <NSObject>

@optional

//被叫收到主叫的提醒
- (void)calledPartyReceiveRemind:(EMMessage *)message callSessionType:(EMCallSessionType)callSessionType;

//主叫收到被叫的唤醒cmd，重发callSession
- (void)callPartyReceiveRemind:(NSDictionary *)info callSessionType:(EMCallSessionType)callSessionType;

@end


@interface RemindAvManager : NSObject

+ (RemindAvManager *)manager;

#pragma mark - 委托

- (void)addDelegate:(id<RemindAvDelegate>)delegate;

- (void)removeDelegate;

#pragma mark -

//向主叫方发送cmd消息，重建callSession
- (void)sendRemindCMD:(NSString *)chatter sessionType:(EMCallSessionType)sessionType;

//向被叫方发出唤醒的消息，作为远程通知
- (void)sendRemindMessage:(NSString *)chatter sessionType:(EMCallSessionType)sessionType;

//开启runloop，定时
- (void)startRunLoop:(id)target action:(SEL)action;

//结束runloop
- (void)stopRunLoop;

//显示音视频唤醒的本地通知
- (void)showNotificationRemind:(NSDictionary *)userInfo;

@end
