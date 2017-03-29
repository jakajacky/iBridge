//
//  BLEPedometerService.h
//  iBridgeLib
//
//  Created by qiuwenqing on 15/12/10.
//  Copyright © 2015年 IVT. All rights reserved.
//

#import "BLEService.h"
@class BLEPedometerService;

@protocol BLEPedometerServiceDelegate <NSObject>

#pragma mark - BLEPedometerServiceDelegate

#pragma mark 启动服务的结果,调用start之后会产生此事件
- (void)blePedometerService:(nonnull BLEPedometerService *)blePedometerService didStart:(BOOL)result;

#pragma mark 接收步数
- (void)blePedometerService:(nonnull BLEPedometerService *)blePedometerService didCountOfStepsReceived:(nonnull NSString *)steps;

@end

@interface BLEPedometerService : BLEService

#pragma mark 启动服务
#pragma mark 在连接成功之后(didDisconnectPeripheral)才能调用
#pragma mark 会触发didStart
- (BOOL)start:(nonnull CBPeripheral *)peripheral;

#pragma mark 停止服务
- (void)stop;

#pragma mark - 公用属性
@property(weak,nonatomic) id<BLEPedometerServiceDelegate> delegate;

@end
