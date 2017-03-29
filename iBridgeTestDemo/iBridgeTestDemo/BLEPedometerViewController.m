//
//  BraceletViewController.m
//  iBridgeTestDemo
//
//  Created by qiuwenqing on 15/11/2.
//  Copyright © 2015年 IVT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEPedometerViewController.h"
#import "BLEManager.h"
#import "BLEGATTService.h"
#import "BLEPedometerService.h"

@interface BLEPedometerViewController() <BLEPedometerServiceDelegate>
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) BLEPedometerService *blePedometerService;

@property (weak, nonatomic) IBOutlet UILabel *receivedDataTextField;

- (IBAction)back:(id)sender;

@end

@implementation BLEPedometerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _blePedometerService = [[BLEPedometerService alloc] init];
    [_blePedometerService setDelegate:self];
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:false completion:nil];
}

- (void)setPeripheral:(CBPeripheral *)peripheral {
    _peripheral = peripheral;
    NSLog(@"[PedometerViewController]Start service...");
    [_blePedometerService start:peripheral];
}

#pragma mark 启动服务的结果,调用start之后会产生此事件
- (void)blePedometerService:(nonnull BLEPedometerService *)blePedometerService didStart:(BOOL)result {
    if (result == TRUE) {
        NSLog(@"[PedometerViewController]Service started");
    } else {
        NSLog(@"[PedometerViewController]Service start fail");
    }
}

#pragma mark 接收步数
- (void)blePedometerService:(nonnull BLEPedometerService *)blePedometerService didCountOfStepsReceived:(nonnull NSString *)steps {
    [_receivedDataTextField setText:steps];
}

@end
