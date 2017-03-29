//
//  BLEHRMeasurement.h
//  iBridgeLib
//
//  Created by qiuwenqing on 15/11/17.
//  Copyright © 2015年 IVT. All rights reserved.
//

#import <Foundation/Foundation.h>

extern unsigned char const BLEHRMeasurementSensorContactStatusNotSupported;
extern unsigned char const BLEHRMeasurementSensorContactStatusNotSupported_;
extern unsigned char const BLEHRMeasurementSensorContactStatusSupportedNotDetected;
extern unsigned char const BLEHRMeasurementSensorContactStatusSupportedDetected;

@interface BLEHRMeasurement : NSObject

+ (id)bleHrMeasurementWithData:(Byte *)bytes;

@property Boolean valueFormatUint16;        //true for uint16,false for uint8
@property unsigned char sensorContactStatus;
@property Boolean energyExpendedAvailable;
@property Boolean rrIntervalAvailable;
@property unsigned short measurementValue;  //unit:beats_per_minute
@property unsigned short energyExpended;    //unit:joule
@property unsigned short rrInterval;        //unit:second

@end
