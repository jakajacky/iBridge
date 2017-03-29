//
//  EASessionViewController.m
//  iBridgeTestDemo
//
//  Created by qiuwenqing on 15/9/21.
//  Copyright © 2015年 IVT. All rights reserved.
//

#include <sys/time.h>
#import "EASessionViewController.h"
#import "EASessionController.h"

@interface EASessionViewController() <EASessionControllerDelegate,  UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    NSThread* autoWriteThread;
}

@property (weak, nonatomic) IBOutlet UITableView *eaaccessoryTableView;
@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
@property (weak, nonatomic) IBOutlet UITextField *receivedDataTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *cleanButton;
@property (weak, nonatomic) IBOutlet UITextField *blockSizeTextField;
@property (weak, nonatomic) IBOutlet UITextField *autoSendTimesTextField;
@property (weak, nonatomic) IBOutlet UITextField *intervalTextField;
@property (weak, nonatomic) IBOutlet UIButton *startAutoSendWithResponseButton;
@property (weak, nonatomic) IBOutlet UIButton *startAutoSendWithoutResponseButton;
@property (weak, nonatomic) IBOutlet UILabel *connStatusLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sendFormatSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *recvFormatSegmentedControl;
@property (weak, nonatomic) IBOutlet UISwitch *autoSendAfterConnectedSwitch;

@property (assign, nonatomic) long bytesReceived;
@property (assign, nonatomic) long availableBufferSize;

- (IBAction)sendText:(UIButton *)sender;
- (IBAction)cleanText:(id)sender;
- (IBAction)startAutoSend:(UIButton *)sender;
- (IBAction)back:(id)sender;
- (IBAction)changeSendFormat:(UISegmentedControl *)sender;
- (IBAction)changeRecvFormat:(id)sender;

@property (weak, nonatomic) EASessionController *eaaccessoryController;
@property (strong, nonatomic) NSMutableArray *listDataAccessory;
@end

@implementation EASessionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _eaaccessoryController = [EASessionController sharedInstance];
    [_eaaccessoryController setDelegate:self];
     _listDataAccessory = [[NSMutableArray alloc] initWithArray:[_eaaccessoryController getAccessorys]];
    
    _bytesReceived = 0;
    _availableBufferSize = 128;
    
    [_sendTextField setText:@"01234567890"];
    [_blockSizeTextField setText:@"100"];
    [_intervalTextField setText:@"100"];
    [_autoSendTimesTextField setText:@"10"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - 代理:UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_listDataAccessory count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *eaAccessoryCellIdentifier = @"eaAccessoryCellIdentifier";
    NSUInteger row = [indexPath row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:eaAccessoryCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:eaAccessoryCellIdentifier];
    }
    
    NSString *eaAccessoryName = [[_listDataAccessory objectAtIndex:row] name];
    if (!eaAccessoryName || [eaAccessoryName isEqualToString:@""]) {
        eaAccessoryName = @"unknown";
    }
    
    [[cell textLabel] setText:eaAccessoryName];
    [[cell textLabel] setFont:[UIFont systemFontOfSize:17]];
    
    if (_eaaccessoryController.state == SESSION_CONNECTED) {
        for (int i = 0; i < _listDataAccessory.count; i++) {
            if ([_listDataAccessory objectAtIndex:i] == [_eaaccessoryController accessory]) {
                [_eaaccessoryTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:false scrollPosition:UITableViewScrollPositionNone];
                NSLog(@"[EASessionViewController]It is conneted device");
                break;
            }
        }
    }
    else if (_eaaccessoryController.state == SESSION_IDLE) {
        for (int i = 0; i < _listDataAccessory.count; i++) {
            if ([_listDataAccessory objectAtIndex:i] == [_eaaccessoryController accessory]) {
                [_eaaccessoryTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:false];
                NSLog(@"[EASessionViewController]It is not connected device");
                break;
            }
        }
    }
    
    return cell;
}

#pragma mark - 代理:UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EAAccessory *selectedAccessory = [_listDataAccessory objectAtIndex:[indexPath row]];
    [_eaaccessoryTableView deselectRowAtIndexPath:indexPath animated:false];
    if ([_eaaccessoryController state] == SESSION_IDLE) {
        [_eaaccessoryController connect:selectedAccessory withProtocolString:@"com.ivtcorporation.com.ibridge"];
    } else if (([_eaaccessoryController state] == SESSION_CONNECTED) && ([_eaaccessoryController accessory] == selectedAccessory)) {
        [_eaaccessoryController disconnect];
    }
    [tableView reloadData];
}

#pragma mark - 代理:EASessionControllerDelegate

#pragma mark 外设接入
-(void) didEAAccessoryPlug:(EAAccessory *)eaAccessory {
    NSLog(@"[EASessionViewController]didEAAccessoryConnected");
    if (![_listDataAccessory containsObject:eaAccessory]) {
        [_listDataAccessory addObject:eaAccessory];
    }
    [_eaaccessoryTableView reloadData];
}

#pragma mark 外设移除
-(void) didEAAccessoryUnplug:(EAAccessory *)eaAccessory {
    NSLog(@"[EASessionViewController]didEAAccessoryDisconnected");
    if ([_listDataAccessory containsObject:eaAccessory]) {
        [_listDataAccessory removeObject:eaAccessory];
    }
    [_eaaccessoryTableView reloadData];
}

#pragma mark 状态改变
#pragma mark 可以通过easession.state获取当前状态
-(void) didEASessionStateChanged:(EASessionController *)easession {
    NSLog(@"[EASessionViewController]didEASessionStateChanged to %d", easession.state);
    if (easession.state == SESSION_CONNECTED) {
        [_connStatusLabel setText:@"连接成功"];
        if (_autoSendAfterConnectedSwitch.isOn) {
            _availableBufferSize = 128;
            autoWriteThread = [[NSThread alloc] initWithTarget:self
                                                      selector:@selector(autoWriteThreadProc:)
                                                        object:nil];
            [autoWriteThread start];
        }
    } else if (easession.state == SESSION_IDLE) {
        [_connStatusLabel setText:@"没有设备连接"];
        if (_autoSendAfterConnectedSwitch.isOn) {
            _availableBufferSize = 128;
            [autoWriteThread cancel];
        }
    }
    [_eaaccessoryTableView reloadData];
}

- (void) autoWriteThreadProc:(id)sender {
    int j = 0;
    static BOOL running = false;
    [NSThread sleepForTimeInterval:2];
    _availableBufferSize = 128;
    if (running == false) {
        running = true;
        while(SESSION_CONNECTED == _eaaccessoryController.state) {
            @synchronized(self) {
                if (_availableBufferSize > 0) {
                    NSString *string_to_send = [sampleStringToSend substringFromIndex:sampleStringToSend.length - (_availableBufferSize - 6)];
                    string_to_send = [string_to_send stringByAppendingString:[NSString stringWithFormat:@"%04d\r\n", j++]];
                    NSLog(@"i=%d", j);
                    _availableBufferSize = 0;
                    [_eaaccessoryController writeData:[string_to_send dataUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@"writen");
                }
            }
        }
        running = false;
        NSLog(@"Thread exit");
    } else {
        NSLog(@"Already running");
    }
}

#pragma mark 数据接收
#pragma mark 可以通过service.revData获取接收到的数据
-(void) didEASessionUpdated:(EASessionController *)easession withData:(NSData *)data {
    NSString *receivedDataToString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [_receivedDataTextField setText:receivedDataToString];
    _bytesReceived += [data length];
    [_connStatusLabel setText:[NSString stringWithFormat:@"接收:%ldbytes", _bytesReceived]];
    if (_autoSendAfterConnectedSwitch.isOn) {
        @synchronized(self) {
            Byte *bytes = (Byte *)data.bytes;
            _availableBufferSize += bytes[1] * 8 + bytes[2];
            NSLog(@"%@", [NSString stringWithFormat:@"%08lx",_availableBufferSize]);
        }
    }
}

#pragma mark - 代理:UITextFieldDelegate

#pragma mark 回车时关闭键盘
-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField endEditing:true];
    return [textField.text length] > 0;
}

#pragma mark - 按钮响应

- (IBAction)changeRecvFormat:(id)sender {
}

- (IBAction)sendText:(UIButton *)sender {
    [_sendTextField endEditing:true];
    NSString *stringToSend = _sendTextField.text;
    stringToSend = [stringToSend stringByAppendingString:@"\r\n"];
    [_eaaccessoryController writeData:[stringToSend dataUsingEncoding:NSUTF8StringEncoding]];
}

- (IBAction)cleanText:(id)sender {
    _bytesReceived = 0;
    [_receivedDataTextField setText:@""];
}

- (IBAction)startAutoSend:(id)sender {
    [self.blockSizeTextField endEditing:true];
    [self.autoSendTimesTextField endEditing:true];
    [self.intervalTextField endEditing:true];
    NSThread* myThread = [[NSThread alloc] initWithTarget:self
                                                 selector:@selector(autoSendDatas:)
                                                   object:sender];
    [myThread start];
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:false completion:nil];
}

- (IBAction)changeSendFormat:(UISegmentedControl *)sender {
}

extern NSString *sampleStringToSend;

- (void) autoSendDatas:(UIButton *)sender{
    int j = 0;
    
    if(_blockSizeTextField.text.length > 0 && _autoSendTimesTextField.text.length > 0) {
        struct timeval sendStartTimeval;
        struct timeval sendContinueTimeval;
        long bytesSent, bytesTotal, sendSpeed, timeCostInMs;
        gettimeofday(&sendStartTimeval, NULL);
        
        
        //从预设的缓冲区里获取要发送的数据
        NSString *string_to_send = [sampleStringToSend substringFromIndex:sampleStringToSend.length - ([_blockSizeTextField.text intValue] - 6)];
        //根据设置（发送包长/发送方式/发送间隔）发送数据
        int i = 0;
        while(i < [_autoSendTimesTextField.text intValue]) {
            if (_availableBufferSize > 0) {
                string_to_send = [sampleStringToSend substringFromIndex:sampleStringToSend.length - ([_blockSizeTextField.text intValue] - 6)];
                string_to_send = [string_to_send stringByAppendingString:[NSString stringWithFormat:@"%04d\r\n", j++]];
                if(sender == self.startAutoSendWithResponseButton) {
                    [_eaaccessoryController writeData:[string_to_send dataUsingEncoding:NSUTF8StringEncoding]];
                    self.startAutoSendWithoutResponseButton.enabled = false;
                } else if(sender == self.startAutoSendWithoutResponseButton) {
                    if (self.intervalTextField.text.length > 0) {
                        [_eaaccessoryController writeData:[string_to_send dataUsingEncoding:NSUTF8StringEncoding]];
                        [NSThread sleepForTimeInterval:[_intervalTextField.text doubleValue] / 1000];
                        self.startAutoSendWithResponseButton.enabled = false;
                    }
                }
                i++;
                
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
}

@end