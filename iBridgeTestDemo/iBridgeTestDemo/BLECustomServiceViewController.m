//
//  BLECustomServiceViewController.m
//  iBridge
//
//  Created by qiuwenqing on 15/11/19.
//  Copyright © 2015年 IVT. All rights reserved.
//

#include "BLEManager.h"
#import "BLECustomServiceViewController.h"
#import "BLECustomService.h"
#import "BLECharacteristicViewController.h"

@interface BLECustomServiceViewController() <BLECustomServiceDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *characteristicsTableView;

@property (strong, nonatomic) BLECustomService *bleCustomService;

@end

@implementation BLECustomServiceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _bleCustomService = [[BLECustomService alloc] init];
    [_bleCustomService setDelegate:self];
}

- (IBAction)back:(id)sender {
    NSLog(@"[BLECustomServiceViewController]Stop service...");
    [_bleCustomService stop];
    [self dismissViewControllerAnimated:false completion:nil];
}

- (void)setPeripheral:(CBPeripheral *)peripheral serviceUuidString:(NSString *)serviceUuidString {
    NSLog(@"[BLECustomServiceViewController]Start service...");
    [_bleCustomService start:serviceUuidString on:peripheral];
}

#pragma mark - BLECustomServiceDelegate

#pragma mark 启动服务的结果,调用start之后会产生此事件
- (void)bleCustomService:(nonnull BLECustomService *)bleCustomService didStart:(BOOL)result {
    if (result) {
        NSLog(@"[BLECustomServiceViewController]Service started");
    } else {
        NSLog(@"[BLECustomServiceViewController]Service start fail");
    }
    [_characteristicsTableView reloadData];
}

#pragma mark 数据接收
- (void)bleCustomService:(nonnull BLECustomService *)bleCustomService didDataReceived:(nonnull NSData *)data on:(nonnull CBCharacteristic *)characteristic {
}

#pragma mark - 代理:UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_bleCustomService getCharacteristics].count;
}

#pragma mark 在TableView中显示Serive的信息
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"characteristicsTableViewItem"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"characteristicsTableViewItem"];
    }
    
    CBCharacteristic *characteristic = (CBCharacteristic *)[[_bleCustomService getCharacteristics] objectAtIndex:indexPath.row];
    
    NSString *description = [BLEMANAGER getUuidDescription:characteristic.UUID.UUIDString];
    if (description) {
        [cell.textLabel setText:description];
    } else {
        [cell.textLabel setText:characteristic.UUID.UUIDString];
    }
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@(Properties:%@)",characteristic.UUID.UUIDString,[BLEMANAGER getCharacteristicPropertyString:characteristic.properties]]];
 
    return cell;
}

#pragma mark - 代理:UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CBCharacteristic *characteristic = (CBCharacteristic *)[[_bleCustomService getCharacteristics] objectAtIndex:indexPath.row];
    BLECharacteristicViewController *characteristicViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BLECharacteristicViewController"];
    [self presentViewController:characteristicViewController animated:false completion:nil];
    [characteristicViewController setCharacteristic:characteristic service:_bleCustomService];
}

@end
