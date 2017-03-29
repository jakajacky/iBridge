//
//  BLECharacteristicViewController.m
//  iBridge
//
//  Created by qiuwenqing on 15/11/19.
//  Copyright © 2015年 IVT. All rights reserved.
//

#import "BLEManager.h"
#import "BLECharacteristicViewController.h"
#import "BLECustomService.h"

@interface BLECharacteristicViewController() <BLECustomServiceDelegate,UITextFieldDelegate>

@property (strong,nonatomic) CBCharacteristic *characteristic;
@property (strong,nonatomic) BLECustomService *bleCustomService;
@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;
@property (weak, nonatomic) IBOutlet UILabel *peropertyLabel;
@property (weak, nonatomic) IBOutlet UITextField *dataToSendTextField;
@property (weak, nonatomic) IBOutlet UIButton *writeWithResponseButton;
@property (weak, nonatomic) IBOutlet UIButton *writeWithoutResponseButton;
@property (weak, nonatomic) IBOutlet UITextView *reveivedDataTextView;
@property (weak, nonatomic) IBOutlet UIButton *startListenningButton;
@property (weak, nonatomic) IBOutlet UIButton *readButton;

- (IBAction)wrtieWithResponse:(id)sender;
- (IBAction)wrtieWithoutResponse:(id)sender;
- (IBAction)startListenning:(id)sender;
- (IBAction)read:(id)sender;

@end

@implementation BLECharacteristicViewController

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:false completion:nil];
}

- (void)setCharacteristic:(CBCharacteristic *)characteristic service:(BLECustomService *)bleCustomService {
    _characteristic = characteristic;
    _bleCustomService = bleCustomService;
    [_bleCustomService setDelegate:self];
    NSString *description = [BLEMANAGER getUuidDescription:characteristic.UUID.UUIDString];
    if (description) {
        [_uuidLabel setText:description];
    } else {
        [_uuidLabel setText:characteristic.UUID.UUIDString];
    }
    [_peropertyLabel setText:[BLEMANAGER getCharacteristicPropertyString:characteristic.properties]];
    [_startListenningButton setEnabled:((characteristic.properties&CBCharacteristicPropertyNotify) || (characteristic.properties&CBCharacteristicPropertyIndicate))];
    [_writeWithoutResponseButton setEnabled:(characteristic.properties&CBCharacteristicPropertyWriteWithoutResponse)];
    [_writeWithResponseButton setEnabled:(characteristic.properties&CBCharacteristicPropertyWrite)];
    [_dataToSendTextField setEnabled:(characteristic.properties&CBCharacteristicPropertyWriteWithoutResponse) || (characteristic.properties&CBCharacteristicPropertyWrite)];
    [_readButton setEnabled:(characteristic.properties&CBCharacteristicPropertyRead)];
}

- (IBAction)wrtieWithResponse:(id)sender {
    [_bleCustomService write:_characteristic data:[_dataToSendTextField.text dataUsingEncoding:NSUTF8StringEncoding] withResponse:true];
}

- (IBAction)wrtieWithoutResponse:(id)sender {
    [_bleCustomService write:_characteristic data:[_dataToSendTextField.text dataUsingEncoding:NSUTF8StringEncoding] withResponse:false];
}

- (IBAction)startListenning:(id)sender {
    if ([[_startListenningButton titleLabel].text isEqualToString:@"Start Listenning"]) {
        [_bleCustomService listen:_characteristic onoff:true];
        [_startListenningButton setTitle:@"Stop Listenning" forState:UIControlStateNormal];
        [_startListenningButton setTitle:@"Stop Listenning" forState:UIControlStateHighlighted];
        [_startListenningButton setTitle:@"Stop Listenning" forState:UIControlStateDisabled];
        [_startListenningButton setTitle:@"Stop Listenning" forState:UIControlStateSelected];
    } else {
        [_bleCustomService listen:_characteristic onoff:false];
        [_startListenningButton setTitle:@"Start Listenning" forState:UIControlStateNormal];
        [_startListenningButton setTitle:@"Start Listenning" forState:UIControlStateHighlighted];
        [_startListenningButton setTitle:@"Start Listenning" forState:UIControlStateDisabled];
        [_startListenningButton setTitle:@"Start Listenning" forState:UIControlStateSelected];
    }
    
}

- (IBAction)read:(id)sender {
    [_bleCustomService read:_characteristic];
}

#pragma mark - 代理:UITextFieldDelegate

#pragma mark 回车时关闭键盘
-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField endEditing:true];
    return [textField.text length] > 0;
}

#pragma mark - BLECustomServiceDelegate

#pragma mark 启动服务的结果,调用start之后会产生此事件
- (void)bleCustomService:(nonnull BLECustomService *)bleCustomService didStart:(BOOL)result {
    
}

#pragma mark 数据接收
- (void)bleCustomService:(nonnull BLECustomService *)bleCustomService didDataReceived:(nonnull NSData *)data on:(nonnull CBCharacteristic *)characteristic {
    if (characteristic == _characteristic) {
        NSString *asciiString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *hexString = @"";
        Byte bytes[data.length];
        [data getBytes:bytes];
        for (int i = 0; i < data.length; i++) {
            hexString = [hexString stringByAppendingString:[NSString stringWithFormat:@"%02x ",bytes[i]]];
        }
        [_reveivedDataTextView setText:[NSString stringWithFormat:@"String:%@\r\nHex:%@",asciiString,hexString]];
    }
}

@end
