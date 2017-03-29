//
//  BLEServicesViewController.m
//  iBridgeTestDemo
//
//  Created by Michael Zu on 14-2-13.
//  Copyright (c) 2014年 IVT. All rights reserved.
//

#include <sys/time.h>
#import "BLEServicesViewController.h"
#import "BLEManager.h"
#import "BLEGATTService.h"
#import "BLEGATTViewController.h"
#import "BLEHRViewController.h"
#import "BLECustomServiceViewController.h"
#import "BLEPedometerViewController.h"

@interface BLEServicesViewController () <BLEManagerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *serviceTableView;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (weak, nonatomic) IBOutlet UITextView *advDataTextView;
@property (strong, nonatomic) CBPeripheral *peripheral;

- (IBAction)back:(id)sender;

@end

@implementation BLEServicesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"[BLEServicesViewController]viewDidLoad");
    NSLog(@"[BLEServicesViewController]Set BLEManager delegate to %@", self);
    [BLEMANAGER setDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"[BLEServicesViewController]viewDidLoad");
    NSLog(@"[BLEServicesViewController]Set BLEManager delegate to %@", self);
    [BLEMANAGER setDelegate:self];
}

- (IBAction)back:(id)sender {
    NSLog(@"[BLEServicesViewController]back");
    NSLog(@"[BLEServicesViewController]Disconnect...");
    [BLEMANAGER disconnect:_peripheral];
    NSLog(@"[BLEServicesViewController]Set BLEManager delegate to %@", nil);
    [BLEMANAGER setDelegate:nil];
    [self dismissViewControllerAnimated:false completion:nil];
}

#pragma mark - 公共方法

- (void)setPeripheral:(nonnull CBPeripheral *)peripheral rssi:(nullable NSNumber *)rssi advertisementData:(nullable BLEAdvertisementData *)advertisementData {
    _peripheral = peripheral;
    [_navigationItem setTitle:_peripheral.name];
    [_advDataTextView setText:[self getAdervitisementString:advertisementData]];
    NSLog(@"[BLEServicesViewController]Discover services...");
    [BLEMANAGER discoverServices:_peripheral];
}

#pragma mark - 代理:UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _peripheral.services.count;
}

#pragma mark 在TableView中显示Serive的信息
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"serviceTableViewItem"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"serviceTableViewItem"];
    }
    CBService *service = (CBService *)[_peripheral.services objectAtIndex:indexPath.row];
    NSString *description = [BLEMANAGER getUuidDescription:service.UUID.UUIDString];
    if (description) {
        [cell.textLabel setText:description];
    } else {
        [cell.textLabel setText:service.UUID.UUIDString];
    }
    
    [cell.detailTextLabel setText:service.UUID.UUIDString];
    return cell;
}

#pragma mark - 代理:UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CBService *service = (CBService *)[_peripheral.services objectAtIndex:indexPath.row];
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_UUID_IVT_DATA_TRANSMISSION]] || [service.UUID isEqual:[CBUUID UUIDWithString:@"49535343-FE7D-4AE5-8FA9-9FAFD205E455"]]) {
        NSLog(@"[BLEServicesViewController]Set BLEManager delegate to %@", nil);
        [BLEMANAGER setDelegate:nil];
        BLEGATTViewController *viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BLEGATTViewController"];
        [self presentViewController:viewController animated:YES completion:nil];
        [viewController setPeripheral:_peripheral service:service.UUID.UUIDString];
    } else if ([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_UUID_HEART_RATE]]) {
        [BLEMANAGER setDelegate:nil];
        BLEHRViewController *viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BLEHRViewController"];
        [self presentViewController:viewController animated:YES completion:nil];
        [viewController setPeripheral:_peripheral];
    } else if ([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_UUID_IVT_PEDOMETER]]) {
        [BLEMANAGER setDelegate:nil];
        BLEPedometerViewController *viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BLEPedometerViewController"];
        [self presentViewController:viewController animated:YES completion:nil];
        [viewController setPeripheral:_peripheral];
    } else {
        NSLog(@"[BLEServicesViewController]Set BLEManager delegate to %@", nil);
        [BLEMANAGER setDelegate:nil];
        BLECustomServiceViewController *viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BLECustomServiceViewController"];
        [self presentViewController:viewController animated:YES completion:nil];
        [viewController setPeripheral:_peripheral serviceUuidString:service.UUID.UUIDString];
        [tableView deselectRowAtIndexPath:indexPath animated:false];
    }
}

#pragma mark - 代理:BTManagerDelegate

- (void) didUpdateState:(CBCentralManagerState) state {
    NSLog(@"[BLEServicesViewController]BLEManager state changed to %ld", (long)state);
}

#pragma mark 发现设备
- (void) didPeripheralFound:(CBPeripheral *)peripheral advertisementData:(BLEAdvertisementData *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"[BLEServicesViewController]Device found(%@)", peripheral.name);
}

#pragma mark 连接成功
- (void) didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"[BLEServicesViewController]Connected");
}

#pragma mark 连接失败
- (void) didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"[BLEServicesViewController]Fail to connect");
}

#pragma mark 连接断开
- (void) didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"[BLEServicesViewController]Disconnected");
    [self dismissViewControllerAnimated:false completion:nil];
}

#pragma mark 发现服务
- (void) didServicesFound:(CBPeripheral *)peripheral services:(NSArray<CBPeripheral *> *)services {
    NSLog(@"[BLEServicesViewController]%lu services found", (unsigned long)services.count);
    [_serviceTableView reloadData];
}

#pragma mark - 辅助函数

- (NSString *)getAdervitisementString:(BLEAdvertisementData *)advertisementData {
    NSString *advertisementString = @"\r\nAdvertisement Data:\r\n";
    if (advertisementData.localName) {
        advertisementString = [advertisementString stringByAppendingString:@"Local Name:"];
        advertisementString = [advertisementString stringByAppendingString:advertisementData.localName];
        advertisementString = [advertisementString stringByAppendingString:@"\r\n"];
    }
    if (advertisementData.txPowerLevel) {
        advertisementString = [advertisementString stringByAppendingString:@"Tx Power:"];
        advertisementString = [advertisementString stringByAppendingString:advertisementData.txPowerLevel.stringValue];
        advertisementString = [advertisementString stringByAppendingString:@"\r\n"];
    }
    if (advertisementData.serviceUUIDs.count > 0) {
        advertisementString = [advertisementString stringByAppendingString:@"Service UUIDs:\r\n"];
        for (int i = 0; i < advertisementData.serviceUUIDs.count; i++) {
            CBUUID *uuid = (CBUUID *)advertisementData.serviceUUIDs[i];
            advertisementString = [advertisementString stringByAppendingString:@"<"];
            advertisementString = [advertisementString stringByAppendingString:uuid.UUIDString];
            NSData *serviceData = [advertisementData.serviceData valueForKey:uuid.UUIDString];
            if (serviceData.length > 0) {
                advertisementString = [advertisementString stringByAppendingString:@"-"];
                for (int i = 0; i < serviceData.length; i++) {
                    unsigned char bytes[serviceData.length];
                    [serviceData getBytes:bytes];
                    advertisementString = [advertisementString stringByAppendingString:[NSString stringWithFormat:@"%02x", bytes[i]]];
                    ;
                }
            }
            advertisementString = [advertisementString stringByAppendingString:@">"];
            advertisementString = [advertisementString stringByAppendingString:@"\r\n"];
        }
    }
    if (advertisementData.overflowServiceUUIDs.count > 0) {
        advertisementString = [advertisementString stringByAppendingString:@"Overflow Service UUIDs:\r\n"];
        for (int i = 0; i < advertisementData.overflowServiceUUIDs.count; i++) {
            advertisementString = [advertisementString stringByAppendingString:@"<"];
            CBUUID *uuid = (CBUUID *)advertisementData.overflowServiceUUIDs[i];
            advertisementString = [advertisementString stringByAppendingString:uuid.UUIDString];
            advertisementString = [advertisementString stringByAppendingString:@">"];
            advertisementString = [advertisementString stringByAppendingString:@"\r\n"];
        }
    }
    if (advertisementData.solicitedServiceUUIDs.count > 0) {
        advertisementString = [advertisementString stringByAppendingString:@"Solicited Service UUIDs:\r\n"];
        for (int i = 0; i < advertisementData.solicitedServiceUUIDs.count; i++) {
            advertisementString = [advertisementString stringByAppendingString:@"<"];
            CBUUID *uuid = (CBUUID *)advertisementData.solicitedServiceUUIDs[i];
            advertisementString = [advertisementString stringByAppendingString:uuid.UUIDString];
            advertisementString = [advertisementString stringByAppendingString:@">"];
            advertisementString = [advertisementString stringByAppendingString:@"\r\n"];
        }
    }
    if (advertisementData.manufacturerData.length > 0) {
        advertisementString = [advertisementString stringByAppendingString:@"Manufacturer Data:\r\n<"];
        for (int i = 0; i < advertisementData.manufacturerData.length; i++) {
            unsigned char bytes[advertisementData.manufacturerData.length];
            [advertisementData.manufacturerData getBytes:bytes];
            advertisementString = [advertisementString stringByAppendingString:[NSString stringWithFormat:@"%02x", bytes[i]]];
            ;
        }
        advertisementString = [advertisementString stringByAppendingString:@">\r\n"];
    }
    return advertisementString;
}

@end

