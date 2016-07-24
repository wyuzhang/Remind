//
//  RemindAvManager.h
//  ChatDemo-UI3.0
//
//  Created by WYZ on 16/7/22.
//  Copyright © 2016年 WYZ. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RemindAvManager : NSObject

+ (RemindAvManager *)manager;

- (void)sendRemindCMD:(NSString *)chatter sessionType:(EMCallSessionType)sessionType;

- (void)startRunLoop:(id)target action:(SEL)action;

- (void)stopRunLoop;

- (void)showAlert:(NSString *)message;

@end
