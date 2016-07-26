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

- (void)calledPartyReceiveRemind:(EMMessage *)message callSessionType:(EMCallSessionType)callSessionType;

- (void)callPartyReceiveRemind:(NSDictionary *)info callSessionType:(EMCallSessionType)callSessionType;

@end


@interface RemindAvManager : NSObject

+ (RemindAvManager *)manager;

#pragma mark - 委托

- (void)addDelegate:(id<RemindAvDelegate>)delegate;

- (void)removeDelegate;

#pragma mark -

- (void)sendRemindCMD:(NSString *)chatter sessionType:(EMCallSessionType)sessionType;

- (void)sendRemindMessage:(NSString *)chatter sessionType:(EMCallSessionType)sessionType;

- (void)startRunLoop:(id)target action:(SEL)action;

- (void)stopRunLoop;

- (void)showAlert:(NSString *)message;

//- (void)showNotificationRemind:(NSDictionary *)info;

@end
