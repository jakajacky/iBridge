//
//  EASessionController.h
//  iBridge
//
//  Created by Michael Zu on 13-11-1.
//  Copyright (c) 2013年 IVT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>

@class EASessionController;

enum SessionState {
    SESSION_IDLE = 0,
    SESSION_CONNECTED = 1
};

@protocol EASessionControllerDelegate <NSObject>

#pragma mark 外设接入
- (void)didEAAccessoryPlug:(EAAccessory *)eaAccessory;

#pragma mark 外设移除
- (void)didEAAccessoryUnplug:(EAAccessory *)eaAccessory;

#pragma mark 状态改变
#pragma mark 可以通过easession.state获取当前状态
- (void)didEASessionStateChanged:(EASessionController *)easession;

#pragma mark 数据接收
#pragma mark 可以通过service.revData获取接收到的数据
-(void) didEASessionUpdated:(EASessionController *)easession withData:(NSData *)data;

@end

@interface EASessionController : NSObject <EAAccessoryDelegate,NSStreamDelegate>

+ (EASessionController *)sharedInstance;

- (NSArray<EAAccessory *> *)getAccessorys;

- (BOOL)connect:(EAAccessory *)accessory withProtocolString:protocolString;
- (void)disconnect;

- (void)writeData:(NSData *)data;

@property(weak,nonatomic) id<EASessionControllerDelegate> delegate;
@property(readonly, nonatomic) EAAccessory *accessory;
@property(readonly, nonatomic) int state;

@end
