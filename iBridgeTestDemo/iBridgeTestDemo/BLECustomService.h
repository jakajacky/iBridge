//
//  BLECustomService.h
//  iBridgeLib
//
//  Created by qiuwenqing on 15/11/19.
//  Copyright © 2015年 IVT. All rights reserved.
//

#import "BLEService.h"

@class BLECustomService;

@protocol BLECustomServiceDelegate <NSObject>

#pragma mark - BLECustomServiceDelegate

#pragma mark 启动服务的结果,调用start之后会产生此事件
- (void)bleCustomService:(nonnull BLECustomService *)bleCustomService didStart:(BOOL)result;

#pragma mark 数据接收
- (void)bleCustomService:(nonnull BLECustomService *)bleCustomService didDataReceived:(nonnull NSData *)data on:(nonnull CBCharacteristic *)characteristic;

@end

@interface BLECustomService : BLEService

#pragma mark - 公用方法

#pragma mark 监听和停止监听
- (void)listen:(nonnull CBCharacteristic *)characteristic onoff:(BOOL)on;

#pragma mark 读
- (void)read:(nonnull CBCharacteristic *)characteristic;

#pragma mark 发送数据
- (void)write:(nonnull CBCharacteristic *)characteristic data:(nonnull NSData *)data withResponse:(BOOL)withResponse;

#pragma mark - 公用属性
@property(weak,nonatomic) id<BLECustomServiceDelegate> delegate;

@end
