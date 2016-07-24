//
//  RemindAvManager.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 16/7/22.
//  Copyright © 2016年 WYZ. All rights reserved.
//

#import "RemindAvManager.h"

//音频cmd
#define REMIND_CMD_AUDIO                    @"remind_cmd_audio"
//视频cmd
#define REMIND_CMD_VIDEO                    @"remind_cmd_video"

//cmd消息中ext特殊字段
#define CALL_PARTY_USER                     @"call_party_user"  //主叫方
#define CALLED_PARTY_USER                   @"called_party_user"  //被叫方
#define CALL_TYPE                           @"call_type"  //呼叫类型  int类型，0是音频，1是视频

//超时时间
#define CALL_TIMEOUT                        60.0


typedef NS_ENUM(int, CallMessageType) {
    CallMessageType_Audio              =                0,
    CallMessageType_Video,
    CallMessageType_None
};

@interface RemindAvManager()<IChatManagerDelegate> {
    NSRunLoop *_runLoop;
    NSTimer *_timer;
}

@end

@implementation RemindAvManager

+ (RemindAvManager *)manager {
    static RemindAvManager *manager = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        manager = [[RemindAvManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
    }
    return self;
}

- (void)dealloc {
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
}

#pragma mark - IChatManagerDelegate

- (void)didReceiveMessage:(EMMessage *)message {
}

- (void)didReceiveCmdMessage:(EMMessage *)cmdMessage {
    CallMessageType callType = [self isRemindAVCmd:cmdMessage];
    if (callType == CallMessageType_None) {
        return;
    }
    
}

- (void)didReceiveOfflineMessages:(NSArray *)offlineMessages {
}

- (void)didReceiveOfflineCmdMessages:(NSArray *)offlineCmdMessages {
}


#pragma mark - public method

- (void)sendRemindCMD:(NSString *)chatter sessionType:(EMCallSessionType)sessionType {
    NSString *cmd = REMIND_CMD_AUDIO;
    int callType = 0;
    if (sessionType == eCallSessionTypeVideo) {
        cmd = REMIND_CMD_VIDEO;
        callType = 1;
    }
    EMChatCommand *chat = [[EMChatCommand alloc] init];
    chat.cmd = cmd;
    EMCommandMessageBody *body = [[EMCommandMessageBody alloc] initWithChatObject:chat];
    EMMessage *message = [[EMMessage alloc] initWithReceiver:chatter bodies:@[body]];
    message.messageType = eMessageTypeChat;
    message.ext = @{CALL_TYPE:[NSNumber numberWithInt:callType], CALL_PARTY_USER:[[EaseMob sharedInstance].chatManager loginInfo][kSDKUsername], CALLED_PARTY_USER:chatter};
    [[EaseMob sharedInstance].chatManager asyncSendMessage:message progress:nil prepare:nil onQueue:nil completion:^(EMMessage *message, EMError *error) {
        
        if (error) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showAlert:@"cmd没有发送成功"];
            });
        }
        
    } onQueue:nil];
}

- (void)startRunLoop:(id)target action:(SEL)action {
    [self stopRunLoop];
    if (!_runLoop)
    {
        _runLoop = [[NSRunLoop alloc] init];
    }
    
    if (!_timer)
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:CALL_TIMEOUT target:target selector:action userInfo:nil repeats:NO];
    }
    [_runLoop addTimer:_timer forMode:NSRunLoopCommonModes];
    [_runLoop run];
}

- (void)stopRunLoop {
    if (_timer.isValid) {
        [_timer invalidate];
        _timer = nil;
        _runLoop = nil;
    }
}

- (void)showAlert:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - private method

- (CallMessageType)isRemindAVCmd:(EMMessage *)cmdMessage {
    id<IEMMessageBody> body = cmdMessage.messageBodies.firstObject;
    if (![body isKindOfClass:[EMCommandMessageBody class]]) {
        return CallMessageType_None;
    }
    EMCommandMessageBody *cmdBody = (EMCommandMessageBody *)body;
    if ([cmdBody.action isEqualToString:REMIND_CMD_AUDIO]) {
        return CallMessageType_Audio;
    }
    else if ([cmdBody.action isEqualToString:REMIND_CMD_VIDEO]) {
        return CallMessageType_Video;
    }
    return CallMessageType_None;
}

@end
