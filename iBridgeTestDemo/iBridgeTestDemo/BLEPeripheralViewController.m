//
//  BLEPeripheralViewController.m
//  iBridgeTestDemo
//
//  Created by qiuwenqing on 15/9/25.
//  Copyright © 2015年 IVT. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/time.h>
#import "BLEPeripheralViewController.h"
#import "BLEPeripheralManager.h"

@interface BLEPeripheralViewController() <BLEPeripheralDelegate,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
@property (weak, nonatomic) IBOutlet UITextField *receivedDataTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *cleanButton;
@property (weak, nonatomic) IBOutlet UITextField *blockSizeTextField;
@property (weak, nonatomic) IBOutlet UITextField *autoSendTimesTextField;
@property (weak, nonatomic) IBOutlet UITextField *intervalTextField;
@property (weak, nonatomic) IBOutlet UIButton *startAutoSendWithoutResponseButton;
@property (weak, nonatomic) IBOutlet UITextView *connStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *setupService;
@property (weak, nonatomic) IBOutlet UIButton *startAdv;
@property (weak, nonatomic) IBOutlet UIButton *stopAdv;

- (IBAction)sendText:(id)sender;
- (IBAction)cleanText:(id)sender;
- (IBAction)startAutoSend:(UIButton *)sender;
- (IBAction)setupService:(id)sender;
- (IBAction)startAdv:(id)sender;
- (IBAction)stopAdv:(id)sender;
- (IBAction)back:(id)sender;

@property (assign, nonatomic) long bytesReceived;
@property (assign, nonatomic) long timeStartToReceive;
@property (weak, nonatomic) NSTimer *checkDataReceiveTimer;

@property (nonatomic, strong) BLEPeripheralManager *lePeripheralManager;

@end

@implementation BLEPeripheralViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _lePeripheralManager = [BLEPeripheralManager sharedInstance];
    [_lePeripheralManager setDelegate:self];
    
    _bytesReceived = 0;
    _timeStartToReceive = 0;
    
    [_sendTextField setText:@"01234567890"];
    [_blockSizeTextField setText:@"100"];
    [_intervalTextField setText:@"100"];
    [_autoSendTimesTextField setText:@"10"];
}

- (IBAction)sendText:(id)sender {
   [_lePeripheralManager writeData:[_sendTextField.text dataUsingEncoding:NSUTF8StringEncoding]];
}

- (IBAction)cleanText:(id)sender {
    [_receivedDataTextField setText:@""];
}

- (IBAction)startAutoSend:(UIButton *)sender {
    [self.blockSizeTextField endEditing:true];
    [self.autoSendTimesTextField endEditing:true];
    [self.intervalTextField endEditing:true];
    NSThread* myThread = [[NSThread alloc] initWithTarget:self
                                                 selector:@selector(autoSendDatas:)
                                                   object:sender];
    [myThread start];
}

- (IBAction)setupService:(id)sender {
//    [_lePeripheralManager setupSevice:@"FF00" withReadCharacter:@"FF01" withWriteCharacter:@"FF02" withExtendCharacter:@"FF03"];
    // ???: 1、这里指定service、character，那么peripheral不用设置
    [_lePeripheralManager setupSevice:@"FFF0" withReadCharacter:@"FEF1" withWriteCharacter:@"FEF2" withExtendCharacter:@"FEF3"];
}

- (IBAction)startAdv:(id)sender {
    // ???: 这里的TxPowerLevel于实际的TxPower值对应关系
    [_lePeripheralManager startAdvertising:@"Data Transfer" withTxPowerLevel:[NSNumber numberWithInt:-60] withServiceData:NULL withManufacturerData:NULL];
}

- (IBAction)stopAdv:(id)sender {
    [_lePeripheralManager stopAdvertising];
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:false completion:nil];
}

#pragma mark - BLEPeripheralManager Delegate
-(void) didPeripheralSubscribeToCharacteristic {
    NSLog(@"[BLEPeripheralViewController]didPeripheralSubscribeToCharacteristic");
    [_connStatusLabel setText:@"设备连接成功"];
    _bytesReceived = 0;
    _timeStartToReceive = 0;
}

-(void) didPeripheralUnsubscribeToCharacteristic {
    NSLog(@"[BLEPeripheralViewController]didPeripheralUnsubscribeToCharacteristic");
    [_connStatusLabel setText:@"没有设备连接"];
    _bytesReceived = 0;
    _timeStartToReceive = 0;
}

-(void) didPeripheralDataReceive:(NSData *)data {
    NSString *receivedDataToString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [_receivedDataTextField setText:receivedDataToString];
    
    //记录开始接收的时间
    if (_timeStartToReceive == 0) {
        //获取时间并转换成毫秒时间
        struct timeval receiveStartTimeval;
        gettimeofday(&receiveStartTimeval, nil);
        _timeStartToReceive = receiveStartTimeval.tv_sec;
        //用来检查数据是否持续接收的定时器
        _checkDataReceiveTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(checkDataReceive:) userInfo:nil repeats:YES];
    }
    //统计接收数据量
    _bytesReceived += data.length;
    //获取当前时间
    struct timeval receiveContinueTimeval;
    long timeContinueToReceive;
    gettimeofday(&receiveContinueTimeval, nil);
    timeContinueToReceive = receiveContinueTimeval.tv_sec;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_connStatusLabel setText:[NSString stringWithFormat:@"接收:%ld, 速度:%ld(Bps)", _bytesReceived, _bytesReceived / (timeContinueToReceive - _timeStartToReceive)]];});
}

#pragma mark -
#pragma mark -
#pragma mark - 开始实现UITextFieldDelegate

#pragma mark - 回车时关闭键盘
-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField endEditing:true];
    return [textField.text length] > 0;
}
#pragma mark - 完成实现UITextFieldDelegate

extern NSString *sampleStringToSend;

- (void) autoSendDatas:(UIButton *)sender{
    if(_blockSizeTextField.text.length > 0 && _autoSendTimesTextField.text.length > 0) {
        struct timeval sendStartTimeval;
        struct timeval sendContinueTimeval;
        long bytesSent, bytesTotal, sendSpeed, timeCostInMs;
        gettimeofday(&sendStartTimeval, NULL);
        
        //从预设的缓冲区里获取要发送的数据
        NSString *string_to_send = [sampleStringToSend substringFromIndex:sampleStringToSend.length - [_blockSizeTextField.text intValue]];
        //根据设置（发送包长/发送方式/发送间隔）发送数据
        for (int i=0; i<[_autoSendTimesTextField.text intValue]; i++) {
            if (self.intervalTextField.text.length > 0) {
                [_lePeripheralManager writeData:[string_to_send dataUsingEncoding:NSUTF8StringEncoding]];
                if ([_intervalTextField.text doubleValue] > 0) {
                    [NSThread sleepForTimeInterval:[_intervalTextField.text doubleValue] / 1000];
                }
            }
            
            //计算和显示发送速度
            bytesSent = (i+1) * [_blockSizeTextField.text intValue];
            bytesTotal = [_blockSizeTextField.text intValue] * [_autoSendTimesTextField.text intValue];
            gettimeofday(&sendContinueTimeval, NULL);
            timeCostInMs = (sendContinueTimeval.tv_sec - sendStartTimeval.tv_sec);
            sendSpeed = bytesSent / timeCostInMs;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_connStatusLabel setText:[NSString stringWithFormat:@"发送:%ld, 速度:%ld(Bps)", bytesSent, sendSpeed]];});
        }
    }
}

#pragma mark - 定时器:检查是否持续有数据接收到，用于计算接收速度
- (void) checkDataReceive:(NSTimer *)timer {
    static long previousBytesReceived = 0;
    if(previousBytesReceived == _bytesReceived) {
        if (_bytesReceived > 0) {
            [_checkDataReceiveTimer invalidate];
        }
        _timeStartToReceive = 0;
        _bytesReceived = 0;
    }
    previousBytesReceived = _bytesReceived;
}

@end
