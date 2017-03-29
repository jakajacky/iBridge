//
//  BLEDevicesViewController.m
//  iBridgeTestDemo
//
//  Created by Michael Zu on 14-2-13.
//  Copyright (c) 2014年 IVT. All rights reserved.
//

#include <sys/time.h>
#import "BLEDevicesViewController.h"
#import "BLEManager.h"
#import "BLEGATTService.h"
#import "BLEServicesViewController.h"

@interface BLEDevicesViewController () <UITextFieldDelegate,BLEManagerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *peripheralTableView;
@property (strong, nonatomic) NSMutableArray *listDataPeripheral;
@property (strong, nonatomic) NSMutableArray *listDataAdvertisement;
@property (strong, nonatomic) NSMutableArray *listDataRSSI;
@property (strong,nonatomic)UIRefreshControl *refresh;

- (IBAction)back:(id)sender;

@end

@implementation BLEDevicesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //ViewController实现BLEServiceDelegate和LeDiscoveryDelegate协议
    [BLEMANAGER setDelegate:self];
    NSLog(@"[BLEDevicesViewController]viewDidLoad");
    NSLog(@"[BLEDevicesViewController]Set BLEManager Deleagte to %@", self);
    
    //用于保存peripheralTableView数据的数组
    _listDataPeripheral = [[NSMutableArray alloc] init];
    _listDataAdvertisement = [[NSMutableArray alloc] init];
    _listDataRSSI = [[NSMutableArray alloc] init];
    
    [self setBeginRefreshing];
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"[BLEDevicesViewController]viewDidAppear");
    NSLog(@"[BLEDevicesViewController]Set BLEManager deleagte to %@", self);
    [BLEMANAGER setDelegate:self];
    NSLog(@"[BLEDevicesViewController]Start scan...");
    [BLEMANAGER scanForPeripherals:nil];
    [_peripheralTableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    NSLog(@"[BLEDevicesViewController]viewDidDisappear");
    NSLog(@"[BLEDevicesViewController]Stop Scan");
    [BLEMANAGER stopScan];
}

- (IBAction)back:(id)sender {
    NSLog(@"[BLEDevicesViewController]back");
    NSLog(@"[BLEDevicesViewController]Set BLEManager deleagte to %@", nil);
    [BLEMANAGER setDelegate:nil];
    [self dismissViewControllerAnimated:false completion:nil];
}

#pragma mark - 刷新控制

#pragma mark 开始刷新
- (void)setBeginRefreshing
{
    _refresh = [[UIRefreshControl alloc]init];
    //刷新图形颜色
    _refresh.tintColor = [UIColor lightGrayColor];
    //刷新的标题
    _refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"下拉搜索"];
    
    // UIRefreshControl 会触发一个UIControlEventValueChanged事件，通过监听这个事件，我们就可以进行类似数据请求的操作了
    [_refresh addTarget:  self action:@selector(refreshTableviewAction:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = _refresh;
    
}

-(void)refreshTableviewAction:(UIRefreshControl *)refreshs
{
    [_listDataPeripheral removeAllObjects];
    [_listDataAdvertisement removeAllObjects];
    [_listDataRSSI removeAllObjects];
    
    NSLog(@"[BLEDevicesViewController]Start scan...");
    [BLEMANAGER scanForPeripherals:nil];
    [self.refreshControl endRefreshing];
    /*
    if (refreshs.refreshing) {
        refreshs.attributedTitle = [[NSAttributedString alloc]initWithString:@"正在搜索"];
        [self performSelector:@selector(endRefresh) withObject:nil afterDelay:1];
    }
     */
}

#pragma mark 停止刷新
-(void)endRefresh
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"]; //创建的时间格式
    
    NSString *lastUpdated = [NSString stringWithFormat:@"上一次更新时间为 %@", [formatter stringFromDate:[NSDate date]]];
    
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated] ;
    [self.refreshControl endRefreshing];
}

#pragma mark - 代理:BTManagerDelegate

- (void) didUpdateState:(CBCentralManagerState) state {
    NSLog(@"[BLEDevicesViewController]BLEManager state changed to %ld", (long)state);
}

#pragma mark 发现设备
- (void) didPeripheralFound:(CBPeripheral *)peripheral advertisementData:(BLEAdvertisementData *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"[BLEDevicesViewController]Device found:%@", peripheral.name);
    if ([_listDataPeripheral indexOfObjectIdenticalTo:peripheral] == LONG_MAX) {
        NSLog(@"[BLEDevicesViewController]Add device to list");
        [_listDataPeripheral addObject:peripheral];
        [_listDataAdvertisement addObject:advertisementData];
        [_listDataRSSI addObject:RSSI];
    } else {
        NSUInteger i = [_listDataPeripheral indexOfObjectIdenticalTo:peripheral];
        [_listDataRSSI removeObjectAtIndex:i];
        [_listDataRSSI insertObject:RSSI atIndex:i];
        NSLog(@"[BLEDevicesViewController]Device exist");
    }
    [_peripheralTableView reloadData];
}

#pragma mark 连接成功
- (void) didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"[BLEDevicesViewController]Connected");
    for (int i = 0; i < _listDataPeripheral.count; i++) {
        if ([_listDataPeripheral objectAtIndex:i] == peripheral) {
            [_peripheralTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:false scrollPosition:UITableViewScrollPositionNone];
            BLEServicesViewController *viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BLEServicesViewController"];
            [self presentViewController:viewController animated:YES completion:nil];
            [viewController setPeripheral:peripheral rssi:[_listDataRSSI objectAtIndex:i] advertisementData:[_listDataAdvertisement objectAtIndex:i]];
        }
    }
}

#pragma mark 连接失败
- (void) didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"[BLEDevicesViewController]Fail to connect");
}

#pragma mark 连接断开
- (void) didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"[BLEDevicesViewController]Disconnected");
    for (int i = 0; i < _listDataPeripheral.count; i++) {
        if ([_listDataPeripheral objectAtIndex:i] == peripheral) {
            [_peripheralTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:false];
        }
    }
}

#pragma mark 发现服务
- (void) didServicesFound:(CBPeripheral *)peripheral services:(NSArray<CBPeripheral *> *)services {
    NSLog(@"[BLEDevicesViewController]%lu services found", (unsigned long)services.count);
}

#pragma mark - 代理:UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _listDataPeripheral.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"peripheralTableViewItem"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"peripheralTableViewItem"];
    }
    if (_listDataPeripheral.count > indexPath.row) {
        CBPeripheral *peripheral = (CBPeripheral *)[_listDataPeripheral objectAtIndex:indexPath.row];
        NSNumber *rssi = (NSNumber *)[_listDataRSSI objectAtIndex:indexPath.row];
        BLEAdvertisementData *bleAdvertisementData = (BLEAdvertisementData *)[_listDataAdvertisement objectAtIndex:indexPath.row];
        if(peripheral.name.length == 0) {
            [cell.textLabel setText:@"Unknown"];
        } else {
            [cell.textLabel setText:peripheral.name];
        }
        [cell.detailTextLabel setText:[NSString stringWithFormat:@"<RSSI:%d>,<TxPowerLevel=%d>,<%lu services>", rssi.intValue, bleAdvertisementData.txPowerLevel.intValue ,(unsigned long)bleAdvertisementData.serviceUUIDs.count]];
    }

    return cell;
}

#pragma mark - 代理:UITableViewDelegate

#pragma mark - 点击TableView条目时，连接/断开条目对应的Peripheral
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CBPeripheral *peripheral = (CBPeripheral *)[_listDataPeripheral objectAtIndex:indexPath.row];
    switch ([peripheral state]) {
        case CBPeripheralStateConnected:
            NSLog(@"[BLEDevicesViewController]Disconnect...");
            [BLEMANAGER disconnect:peripheral];
            break;
        case CBPeripheralStateDisconnected:
            NSLog(@"[BLEDevicesViewController]Stop scan...");
            [BLEMANAGER stopScan];
            [tableView deselectRowAtIndexPath:indexPath animated:true];
            NSLog(@"[BLEDevicesViewController]Connect...");
            [BLEMANAGER connect:peripheral];
            break;
        default:
            break;
    }
}

@end

