//
//  BLEPeripheralManager.h
//  iBridgeLib
//
//  Created by qiuwenqing on 15/9/24.
//  Copyright © 2015年 IVT. All rights reserved.
//

#ifndef BLEPeripheralManager_h
#define BLEPeripheralManager_h

@protocol BLEPeripheralDelegate <NSObject>

-(void) didPeripheralSubscribeToCharacteristic;
-(void) didPeripheralUnsubscribeToCharacteristic;
-(void) didPeripheralDataReceive:(NSData *)data;

@end

@interface BLEPeripheralManager : NSObject

#pragma mark - 共用实例
+ (id) sharedInstance;

- (void) setupSevice:(NSString *) serviceUUID withReadCharacter:(NSString *) readCharacteristicUUID withWriteCharacter:(NSString *) writeCharacteristicUUID withExtendCharacter:(NSString *) extendCharacteristicUUID;
- (void) removeService;

- (void) startAdvertising : (NSString *)localName withTxPowerLevel:(NSNumber *)txPowerLevel withServiceData:(NSData *)serviceData
      withManufacturerData:(NSData *)manufacturerData;
- (void) stopAdvertising;

- (BOOL) writeData:(NSData *) writeData;

@property(weak,nonatomic) id<BLEPeripheralDelegate> delegate;

@end

#endif /* BLEPeripheralManager_h */
