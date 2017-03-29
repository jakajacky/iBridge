//
//  BLEGATTViewController.m
//  iBridgeTestDemo
//
//  Created by Michael Zu on 14-2-13.
//  Copyright (c) 2014年 IVT. All rights reserved.
//

#include <sys/time.h>
#import "BLEGATTViewController.h"
#import "BLEManager.h"
#import "BLEGATTService.h"

@interface BLEGATTViewController () <BLEGATTServiceDelegate, BLEManagerDelegate, UITextFieldDelegate>

@property (strong, nonatomic) BLEGATTService *bleGattService;

@property (weak, nonatomic) IBOutlet UITextView *characteristicsTextView;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (weak, nonatomic) IBOutlet UITextField *receivedDataTextField;
@property (weak, nonatomic) IBOutlet UIButton *cleanBtn;
@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UITextField *blockSizeTextField;
@property (weak, nonatomic) IBOutlet UIButton *startAutoSendButton;
@property (weak, nonatomic) IBOutlet UIButton *stopAutoSendButton;
@property (weak, nonatomic) IBOutlet UITextField *autoSendTimesTextField;
@property (weak, nonatomic) IBOutlet UITextField *intervalTextField;
@property (weak, nonatomic) IBOutlet UILabel *connStatusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *withResponseSwitch;

@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) NSMutableArray *listDataPeripheral;
@property (nonatomic) long bytesReceived;
@property (nonatomic) long timeStartToReceive;
@property (weak, nonatomic) NSTimer *checkDataReceiveTimer;
@property (nonatomic) BOOL autoSending;

- (IBAction)sendText:(id)sender;
- (IBAction)cleanText:(id)sender;
- (IBAction)startAutoSend:(UIButton *)sender;
- (IBAction)back:(id)sender;
- (IBAction)stopAutoSend:(id)sender;

@end

@implementation BLEGATTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _bleGattService = [[BLEGATTService alloc] init];
    [_bleGattService setDelegate:self];
    NSLog(@"[BLEGATTViewController]viewDidLoad");
    NSLog(@"[BLEGATTViewController]Set BLEManager Deleagte to %@", self);
    
    //用于保存characteristicTableView数据的数组
    _listDataPeripheral = [[NSMutableArray alloc] init];
    
    [_blockSizeTextField setText:@"100"];
    [_autoSendTimesTextField setText:@"1000"];
    [_intervalTextField setText:@"0"];
    [_sendTextField setText:@"01234567890123456789"];
    
    //初始化
    _bytesReceived = 0;
    _timeStartToReceive = 0;
    _autoSending = false;
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"[BLEGATTViewController]viewDidAppear");
    NSLog(@"[BLEGATTViewController]Set BLEManager Deleagte to %@", self);
    [BLEMANAGER setDelegate:self];
}

#pragma mark 按钮:清除发送文本
- (IBAction)cleanText:(id)sender{
    [self.receivedDataTextField setText:@""];
    [self.connStatusLabel setText:@""];
}

#pragma mark 按钮:发送文本框中的数据
- (IBAction)sendText:(id)sender {
    [_sendTextField endEditing:true];
    if (_bleGattService.writeCharacteristicProperties & CBCharacteristicPropertyWrite) {
        [_bleGattService write:[_sendTextField.text dataUsingEncoding:NSUTF8StringEncoding] withResponse:true];
    } else {
        if (_bleGattService.writeCharacteristicProperties & CBCharacteristicPropertyWriteWithoutResponse) {
            [_bleGattService write:[_sendTextField.text dataUsingEncoding:NSUTF8StringEncoding] withResponse:false];
        }
    }
}

#pragma mark 按钮:使用线程发送大量数据
- (IBAction)startAutoSend:(UIButton *)sender {
    _autoSending = true;
    [self.blockSizeTextField endEditing:true];
    [self.autoSendTimesTextField endEditing:true];
    [self.intervalTextField endEditing:true];
    NSThread* myThread = [[NSThread alloc] initWithTarget:self
                                                 selector:@selector(autoSendDataThreadProc:)
                                                   object:sender];
    [myThread start];
}

- (IBAction)back:(id)sender {
    NSLog(@"[BLEGATTViewController]back");
    NSLog(@"[BLEGATTViewController]Set BLEManager Deleagte to %@", nil);
    [BLEMANAGER setDelegate:nil];
    NSLog(@"[BLEGATTViewController]Stop service...");
    [_bleGattService stop];
    [self dismissViewControllerAnimated:false completion:nil];
}

- (IBAction)stopAutoSend:(id)sender {
    _autoSending = false;
}

- (void)setPeripheral:(CBPeripheral *)peripheral service:(nonnull NSString *)serviceUuid {
    _peripheral = peripheral;
    [_navigationItem setTitle:[NSString stringWithFormat:@"%@(%@)",_peripheral.name,serviceUuid]];
    NSLog(@"[BLEGATTViewController]Start service...");
    [_bleGattService start:serviceUuid on:_peripheral];
}

#pragma mark - 线程执行函数:根据设置发送数据
- (void) autoSendDataThreadProc:(UIButton *)sender{
    if(_blockSizeTextField.text.length > 0 && _autoSendTimesTextField.text.length > 0) {
        struct timeval sendStartTimeval;
        struct timeval sendContinueTimeval;
        long bytesSent, bytesTotal, sendSpeed, timeCostInMs;
        gettimeofday(&sendStartTimeval, NULL);
        
        //从预设的缓冲区里获取要发送的数据
        NSString *string_to_send = [sampleStringToSend substringFromIndex:sampleStringToSend.length - [_blockSizeTextField.text intValue]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_startAutoSendButton setEnabled:false];
            [_stopAutoSendButton setEnabled:true];});
       

        //根据设置（发送包长/发送方式/发送间隔）发送数据
        for (int i=0; i<[_autoSendTimesTextField.text intValue] && _autoSending; i++) {
            if (_withResponseSwitch.isOn) {
                [_bleGattService write:[string_to_send dataUsingEncoding:NSUTF8StringEncoding] withResponse:true];
            } else {
              [_bleGattService write:[string_to_send dataUsingEncoding:NSUTF8StringEncoding] withResponse:false];
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_startAutoSendButton setEnabled:true];
            [_stopAutoSendButton setEnabled:false];});
    }
}

- (void) autoConnectThreadProc:(UIButton *)sender {
    NSArray<CBPeripheral *> *peripherals = [BLEMANAGER retrievePeripheralsWithIdentifiers:nil];
    if (peripherals.count > 0) {
        while (true) {
            NSLog(@"[BLEGATTViewController]Disonnect...");
            [BLEMANAGER disconnect:_peripheral];
            [NSThread sleepForTimeInterval:2];
            NSLog(@"[BLEGATTViewController]Connect...");
            [BLEMANAGER connect:_peripheral];
            [NSThread sleepForTimeInterval:2];
        }
    }
}

#pragma mark 定时器:检查是否持续有数据接收到，用于计算接收速度
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

#pragma mark - 代理:UITextFieldDelegate

#pragma mark 回车时关闭键盘
-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField endEditing:true];
    return [textField.text length] > 0;
}

#pragma mark - 代理:BLEGATTServiceDelegate

#pragma mark 服务数据接收
-(void)bleGattService:(BLEGATTService *)bleGattService didDataReceived:(NSData *)revData {
    NSString *receivedDataToString = [[NSString alloc] initWithData:revData encoding:NSUTF8StringEncoding];
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
    _bytesReceived += revData.length;
    //获取当前时间
    struct timeval receiveContinueTimeval;
    long timeContinueToReceive;
    gettimeofday(&receiveContinueTimeval, nil);
    timeContinueToReceive = receiveContinueTimeval.tv_sec;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_connStatusLabel setText:[NSString stringWithFormat:@"接收:%ld, 速度:%ld(Bps)", _bytesReceived, _bytesReceived / (timeContinueToReceive - _timeStartToReceive)]];});
}

#pragma mark 服务状态改变
-(void)bleGattService:(BLEGATTService *)bleGattService didStart:(BOOL)result {
    if (result == TRUE) {
        NSLog(@"[BLEGATTViewController]Service started");
        [_characteristicsTextView setText:[self getCharacteristicsPropertyString:[_bleGattService getCharacteristics]]];
        if ((_bleGattService.writeCharacteristicProperties & CBCharacteristicPropertyWrite) && (!(_bleGattService.writeCharacteristicProperties & CBCharacteristicPropertyWriteWithoutResponse)))  {
            [_withResponseSwitch setOn:true animated:false];
            [_withResponseSwitch setEnabled:false];
        }
        if ((!(_bleGattService.writeCharacteristicProperties & CBCharacteristicPropertyWrite)) && (_bleGattService.writeCharacteristicProperties & CBCharacteristicPropertyWriteWithoutResponse))  {
            [_withResponseSwitch setOn:false animated:false];
            [_withResponseSwitch setEnabled:false];
        }
    } else {
        NSLog(@"[BLEGATTViewController]Service start fail");
        [_characteristicsTextView setText:@"No Characteristic Found"];
    }
}

#pragma mark 是否可发送，以及可发送的字节数
- (void)bleGattService:(nonnull BLEGATTService *)bleGattService didFlowControl:(int)credit withMtu:(int)mtu {
    NSLog(@"credit = %d, mtu = %d", credit, mtu);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_sendButton setEnabled:(credit > 0)];
    });
}

#pragma mark - 代理:BLEManagerDelegate

- (void) didUpdateState:(CBCentralManagerState) state {
    NSLog(@"[BLEGATTViewController]BLEManager state changed to %ld", (long)state);
}

#pragma mark 连接建立

- (void)didConnectPeripheral:(CBPeripheral *)peripheral {
     NSLog(@"[BLEGATTViewController]Connected");
    return;
}

#pragma mark 连接断开
- (void) didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"[BLEGATTViewController]Disconnected");
}

#pragma mark - 辅助函数

- (NSString *)getCharacteristicsPropertyString:(NSArray<CBCharacteristic *> *)characteristics {
    NSString *propertiesString = @"\r\nCharacteristics:\r\n";
    for (int i = 0; i < characteristics.count; i++) {
        propertiesString = [propertiesString stringByAppendingString:[characteristics objectAtIndex:i].UUID.UUIDString];
        propertiesString = [propertiesString stringByAppendingString:@"<"];
        NSString *description = [BLEMANAGER getUuidDescription:[characteristics objectAtIndex:i].UUID.UUIDString];
        if (description == nil) {
            description = @"Unknown";
        }
        propertiesString = [propertiesString stringByAppendingString:description];
        propertiesString = [propertiesString stringByAppendingString:@">"];
        propertiesString = [propertiesString stringByAppendingString:@"-"];
        propertiesString = [propertiesString stringByAppendingString:[BLEMANAGER getCharacteristicPropertyString:[characteristics objectAtIndex:i].properties]];
        propertiesString = [propertiesString stringByAppendingString:@"\r\n"];
    }
    return propertiesString;
}

NSString *sampleStringToSend = @"123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890";

@end

