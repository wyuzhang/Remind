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

//超时时间
#define CALL_TIMEOUT                        30.0


typedef NS_ENUM(int, CallMessageType) {
    CallMessageType_Audio              =                0,
    CallMessageType_Video,
    CallMessageType_None
};

@interface RemindAvManager()<IChatManagerDelegate> {
    NSRunLoop *_runLoop;
    NSTimer *_timer;
}

@property (nonatomic, assign) id<RemindAvDelegate> delegate;

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
    [self handleRemindMessage:message];
}

- (void)didReceiveCmdMessage:(EMMessage *)cmdMessage {
    CallMessageType callType = [self isRemindAVCmd:cmdMessage];
    if (callType == CallMessageType_None) {
        return;
    }
    EMCallSessionType type = (EMCallSessionType)callType;
    if (_delegate && [_delegate respondsToSelector:@selector(callPartyReceiveRemind:callSessionType:)])
    {
        [_delegate callPartyReceiveRemind:cmdMessage.ext callSessionType:type];
    }
    
}

- (void)didReceiveOfflineMessages:(NSArray *)offlineMessages {
    __weak typeof(self) weakSelf = self;
    [offlineMessages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[EMMessage class]]) {
            EMMessage *message = (EMMessage *)obj;
            if ([weakSelf handleRemindMessage:message]) {
                *stop = YES;
            }
        }
    }];
}

- (void)didReceiveOfflineCmdMessages:(NSArray *)offlineCmdMessages {
}


#pragma mark - 委托

- (void)addDelegate:(id<RemindAvDelegate>)delegate {
    _delegate = delegate;
}

- (void)removeDelegate {
    _delegate = nil;
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
    message.ext = @{CALL_TYPE:[NSNumber numberWithInt:callType], CALL_PARTY_USER:chatter, CALLED_PARTY_USER:[[EaseMob sharedInstance].chatManager loginInfo][kSDKUsername]};
    [[EaseMob sharedInstance].chatManager asyncSendMessage:message progress:nil prepare:nil onQueue:nil completion:^(EMMessage *message, EMError *error) {
        
        if (error) {
            NSLog(@"发送失败");
        }
        
    } onQueue:nil];
}

- (void)sendRemindMessage:(NSString *)chatter sessionType:(EMCallSessionType)sessionType {
    NSString *callText = @"语音通话";
    int callType = 0;
    if (sessionType == eCallSessionTypeVideo) {
        callText = @"视频通话";
        callType = 1;
    }
    NSString *currentUser = [[EaseMob sharedInstance].chatManager loginInfo][kSDKUsername];
    NSString *text = [NSString stringWithFormat:@"%@向您发起%@",currentUser, callText];
    
    EMChatText *chat = [[EMChatText alloc] initWithText:text];
    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithChatObject:chat];
    EMMessage *message = [[EMMessage alloc] initWithReceiver:chatter bodies:@[body]];
    message.messageType = eMessageTypeChat;
    message.ext = @{CALL_TYPE:[NSNumber numberWithInt:callType], CALL_PARTY_USER:currentUser, CALLED_PARTY_USER:chatter};
    __weak typeof(self) weakSelf = self;
    [[EaseMob sharedInstance].chatManager asyncSendMessage:message progress:nil prepare:nil onQueue:nil completion:^(EMMessage *message, EMError *error) {
        if (error) {
            NSLog(@"发送失败");
        }
        else {
            [weakSelf removeRemindTextMessage:message isNeedDeleteConversation:NO];
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

- (void)showNotificationRemind:(NSDictionary *)userInfo {
    CallMessageType callType = (CallMessageType)[userInfo[CALL_TYPE] intValue];
    if (callType == CallMessageType_None) {
        return;
    }
    NSString *callText = @"语音通话";
    if (callType == CallMessageType_Video) {
        callText = @"视频通话";
    }
    NSString *callPartyUser = userInfo[CALL_PARTY_USER];
    NSString *text = [NSString stringWithFormat:@"%@向您发起%@",callPartyUser, callText];
    
    //发送本地推送
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate date]; //触发通知的时间
    notification.alertAction = NSLocalizedString(@"open", @"Open");
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.alertBody = text;
    notification.userInfo = userInfo;
    //发送通知
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

#pragma mark - private method

//判断cmd消息，当前操作是否为音视频操作
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

//判断文本消息，当前操作是否为音视频操作
- (CallMessageType)isRemindAVMessage:(EMMessage *)message {
    id<IEMMessageBody> body = message.messageBodies.firstObject;
    if (![body isKindOfClass:[EMTextMessageBody class]]) {
        return CallMessageType_None;
    }
    if (!message.ext[CALL_TYPE]) {
        return CallMessageType_None;
    }
    int callType = [message.ext[CALL_TYPE] intValue];
    if (callType == 0) {
        return CallMessageType_Audio;
    }
    else if (callType == 1) {
        return CallMessageType_Video;
    }
    return CallMessageType_None;
}

//删除提示消息
- (void)removeRemindTextMessage:(EMMessage *)message isNeedDeleteConversation:(BOOL)isNeedDeleteConversation {
    EMConversation *conversation = [[EaseMob sharedInstance].chatManager conversationForChatter:message.conversationChatter conversationType:eConversationTypeChat];
    [conversation removeMessageWithId:message.messageId];
    if (isNeedDeleteConversation && !conversation.latestMessage) {
        [[EaseMob sharedInstance].chatManager removeConversationByChatter:conversation.chatter deleteMessages:YES append2Chat:YES];
    }
}

//处理接收到的远程提醒文本类型的消息
- (BOOL)handleRemindMessage:(EMMessage *)message {
    CallMessageType callType = [self isRemindAVMessage:message];
    if (callType == CallMessageType_None) {
        return NO;
    }
    EMCallSessionType type = (EMCallSessionType)callType;
    if (_delegate && [_delegate respondsToSelector:@selector(calledPartyReceiveRemind:callSessionType:)])
    {
        [_delegate calledPartyReceiveRemind:message callSessionType:type];
    }
    [self removeRemindTextMessage:message isNeedDeleteConversation:YES];
    return YES;
}

@end
