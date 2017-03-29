//
//  BLEHRViewController.m
//  iBridge
//
//  Created by qiuwenqing on 15/11/17.
//  Copyright © 2015年 IVT. All rights reserved.
//

#import "BLEHRViewController.h"
#include "BLEHRService.h"
#include "BLEHRMeasurement.h"
#include "BLEManager.h"

@interface BLEHRViewController () <BLEHRServiceDelegate>
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) BLEHRService *bleHRService;

@property (weak, nonatomic) IBOutlet UITextField *bodySensorLocationTextField;
@property (weak, nonatomic) IBOutlet UITextView *measurementTextView;
@property (weak, nonatomic) IBOutlet UIButton *readBodySensorLocationButton;
@property (weak, nonatomic) IBOutlet UIButton *resetEnergyExpendedButton;

- (IBAction)readBodySensorLocation:(id)sender;
- (IBAction)resetEnergyExpended:(id)sender;
- (IBAction)back:(id)sender;

@end

@implementation BLEHRViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _bleHRService = [[BLEHRService alloc] init];
    [_bleHRService setDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [_bleHRService setDelegate:self];
}

- (void)viewDidDisappear:(BOOL)animated {
}

#pragma mark - 公用函数

- (void)setPeripheral:(CBPeripheral *)peripheral {
    _peripheral = peripheral;
    NSLog(@"[BLEHRViewController]Start service...");
    [_bleHRService start:_peripheral];
}

#pragma mark - BLEHRServiceDelegate

#pragma mark 启动服务的结果,调用start之后会产生此事件
- (void)bleHrService:(BLEHRService *)bleHrService didStart:(BOOL)result {
    if (result == TRUE) {
        NSLog(@"[BLEHRViewController]Service started");
    } else {
        NSLog(@"[BLEHRViewController]Service start fail");
        [_bodySensorLocationTextField setEnabled:false];
        [_readBodySensorLocationButton setEnabled:false];
        [_measurementTextView setEditable:false];
        [_measurementTextView setText:@"Service Start Fail"];
        [_resetEnergyExpendedButton setEnabled:false];
    }
}

#pragma mark 接收身体部位信息
#pragma mark bodySensorLocation,比如:BLEHRBodySensorLocationChest
- (void)bleHrService:(BLEHRService *)bleHrService didBodySensorLocationRead:(unsigned char)bodySensorLocation {
    [_bodySensorLocationTextField setText:[self getBodySensorLocationString:bodySensorLocation]];
}

#pragma mark 接收测量数据
- (void)bleHrService:(BLEHRService *)bleHrService didMeasurementReceived:(BLEHRMeasurement *)measurement {
    [_measurementTextView setText:[self getMeasurementString:measurement]];
}

#pragma mark - 辅助函数
- (NSString *)getBodySensorLocationString:(unsigned char)bodySensorLocation {
    if (bodySensorLocation == BLEHRBodySensorLocationChest) {
        return @"Chest";
    } else if (bodySensorLocation == BLEHRBodySensorLocationEarLobe){
        return @"Ear Lobe";
    } else if (bodySensorLocation == BLEHRBodySensorLocationFinger){
        return @"Finger";
    } else if (bodySensorLocation == BLEHRBodySensorLocationFoot){
        return @"Foot";
    } else if (bodySensorLocation == BLEHRBodySensorLocationHand){
        return @"Hand";
    } else if (bodySensorLocation == BLEHRBodySensorLocationWrist){
        return @"Wirst";
    } else if (bodySensorLocation == BLEHRBodySensorLocationOther){
        return @"Other";
    } else {
        return @"Unknown";
    }
}

- (NSString *)getSensorContactStatusString:(unsigned char)sensorContactStatus {
    if (sensorContactStatus == BLEHRMeasurementSensorContactStatusNotSupported) {
        return @"Sensor Contact Not Supported";
    } else if (sensorContactStatus == BLEHRMeasurementSensorContactStatusNotSupported_) {
        return @"Sensor Contact Not Supported";
    } else if (sensorContactStatus == BLEHRMeasurementSensorContactStatusSupportedNotDetected) {
        return @"Sensor Contact Supported but Not Detected";
    } else if (sensorContactStatus == BLEHRMeasurementSensorContactStatusNotSupported) {
        return @"Sensor Contact Supported and Detected";
    } else {
        return @"Sensor Contact Status Illegal";
    }
}

- (NSString *)getMeasurementString:(BLEHRMeasurement *)measurement {
    NSString *measurementString = @"";
    measurementString = [measurementString stringByAppendingString:[self getSensorContactStatusString:measurement.sensorContactStatus]];
    measurementString = [measurementString stringByAppendingString:@"\r\n"];
    measurementString = [measurementString stringByAppendingString:[NSString stringWithFormat:@"Measurement Value is %d beats per minute", measurement.measurementValue]];
    measurementString = [measurementString stringByAppendingString:@"\r\n"];
    if (measurement.energyExpendedAvailable) {
        measurementString = [measurementString stringByAppendingString:[NSString stringWithFormat:@"Energy Expended is %d joules", measurement.energyExpended]];
        measurementString = [measurementString stringByAppendingString:@"\r\n"];
    }
    if (measurement.rrIntervalAvailable) {
        measurementString = [measurementString stringByAppendingString:[NSString stringWithFormat:@"RR Interval is %d seconds", measurement.rrInterval]];
        measurementString = [measurementString stringByAppendingString:@"\r\n"];
    }
    return measurementString;
}

#pragma mark - 按钮响应函数

- (IBAction)readBodySensorLocation:(id)sender {
    [_bleHRService readBodySensorLocation];
}

- (IBAction)resetEnergyExpended:(id)sender {
    [_bleHRService writeControlPoint:BLEHRCommandResetEnergyExpended];
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:false completion:nil];
}
    
@end
