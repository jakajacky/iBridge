//
//  BLEHRService.h
//  iBridgeLib
//
//  Created by qiuwenqing on 15/11/17.
//  Copyright © 2015年 IVT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEService.h"

@class CBPeripheral;
@class CBCharacteristic;
@class BLEHRMeasurement;
@class BLEHRService;

#define BLEHRCommandResetEnergyExpended 1

#define BLEHRBodySensorLocationOther 0
#define BLEHRBodySensorLocationChest 1
#define BLEHRBodySensorLocationWrist 2
#define BLEHRBodySensorLocationFinger 3
#define BLEHRBodySensorLocationHand 4
#define BLEHRBodySensorLocationEarLobe 5
#define BLEHRBodySensorLocationFoot 6

@protocol BLEHRServiceDelegate <NSObject>

#pragma mark - BLEHRServiceDelegate

#pragma mark 启动服务的结果,调用start之后会产生此事件
- (void)bleHrService:(nonnull BLEHRService *)bleHrService didStart:(BOOL)result;

#pragma mark 接收身体部位信息
#pragma mark bodySensorLocation,比如:BLEHRBodySensorLocationChest
- (void)bleHrService:(nonnull BLEHRService *)bleHrService didBodySensorLocationRead:(unsigned char)bodySensorLocation;

#pragma mark 接收测量数据
- (void)bleHrService:(nonnull BLEHRService *)bleHrService didMeasurementReceived:(nonnull BLEHRMeasurement *)measurement;

@end

@interface BLEHRService : BLEService

#pragma mark - 公用方法

#pragma mark 启动服务
#pragma mark 在连接成功之后(didDisconnectPeripheral)才能调用
#pragma mark 会触发didStart
- (BOOL)start:(nonnull CBPeripheral *)peripheral;

#pragma mark 停止服务
- (void)stop;

#pragma mark 写控制点
#pragma mark command:1,Reset Energy Expended: resets the value of the Energy Expended field in the Heart RateMeasurement characteristic to 0; 2-255,Reserved; 0,Reserved.参考:BLEHRCommandResetEnergyExpended.
- (void)writeControlPoint:(unsigned char)command;

#pragma mark 读位置
- (void)readBodySensorLocation;

#pragma mark 

#pragma mark - 公用属性
@property(weak,nonatomic) id<BLEHRServiceDelegate> delegate;

@end
