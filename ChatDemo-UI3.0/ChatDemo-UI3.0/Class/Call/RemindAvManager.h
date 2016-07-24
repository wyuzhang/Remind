//
//  RemindAvManager.h
//  ChatDemo-UI3.0
//
//  Created by WYZ on 16/7/22.
//  Copyright © 2016年 WYZ. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol RemindSenderDelegate <NSObject>

@optional

@end

@protocol RemindReceiverDelegate <NSObject>

@optional

@end


@interface RemindAvManager : NSObject

+ (RemindAvManager *)manager;

#pragma mark - 发送方委托

- (void)addReceiverDelegate:(id<RemindSenderDelegate>)delegate;

- (void)removeReceiverDelegate;

#pragma mark - 接收方委托

- (void)addSenderDelegate:(id<RemindReceiverDelegate>)delegate;

- (void)removeSenderDelegate;

#pragma mark -

- (void)sendRemindCMD:(NSString *)chatter sessionType:(EMCallSessionType)sessionType;

- (void)startRunLoop:(id)target action:(SEL)action;

- (void)stopRunLoop;

- (void)showAlert:(NSString *)message;

@end
