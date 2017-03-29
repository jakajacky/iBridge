//
//  BLEBeaconViewController.m
//  iBridge
//
//  Created by qiuwenqing on 15/12/25.
//  Copyright © 2015年 IVT. All rights reserved.
//

#import "BLEBeaconViewController.h"
@import CoreLocation;

NSString *BeaconIdentifier = @"com.example.ivt-ibridge.beacon";

@interface BLEBeaconViewController() <CLLocationManagerDelegate,UITableViewDataSource>

@property CLBeaconRegion *region;
@property NSArray *beacons;
@property CLLocationManager *locationManager;

@property NSUUID *uuid;
@property NSNumber *major;
@property NSNumber *minor;
@property (nonatomic) NSNumberFormatter *numberFormatter;

@property (weak, nonatomic) IBOutlet UITextField *uuidTextField;
@property (weak, nonatomic) IBOutlet UITextField *majorTextField;
@property (weak, nonatomic) IBOutlet UITextField *minorTextField;
@property (weak, nonatomic) IBOutlet UITableView *beaconTableView;

- (IBAction)start:(id)sender;

@end

@implementation BLEBeaconViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _numberFormatter = [[NSNumberFormatter alloc] init];
    _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    [_locationManager requestAlwaysAuthorization];
    
    [_uuidTextField setText:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];
}

- (void)viewDidDisappear:(BOOL)animated {
    if (_region) {
        [_locationManager stopRangingBeaconsInRegion:_region];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region {
    NSLog(@"didEnterRegion");
}

- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region {
    NSLog(@"didExitRegion");
}

- (void)locationManager:(CLLocationManager *)manager
monitoringDidFailForRegion:(nullable CLRegion *)region
              withError:(NSError *)error {
    NSLog(@"monitoringDidFailForRegion");
}

- (void)locationManager:(CLLocationManager *)manager
didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"didStartMonitoringForRegion");
    [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if(beacons.count > 0) {
        NSLog(@"didRangeBeacons");
    }
    _beacons = beacons;
    [_beaconTableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _beacons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"beaconTableViewItem"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"beaconTableViewItem"];
    }
    
    // Display the UUID, major, minor and accuracy for each beacon.
    CLBeacon *beacon = self.beacons[indexPath.row];
    cell.textLabel.text = [beacon.proximityUUID UUIDString];
    
    NSString *formatString = NSLocalizedString(@"Major: %@, Minor: %@, Acc: %.2fm", @"Format string for ranging table cells.");
    cell.detailTextLabel.text = [NSString stringWithFormat:formatString, beacon.major, beacon.minor, beacon.accuracy];

    return cell;
}

- (IBAction)start:(id)sender {
    _uuid = [[NSUUID alloc] initWithUUIDString:_uuidTextField.text];
    _major = [_numberFormatter numberFromString:_majorTextField.text];
    _minor = [_numberFormatter numberFromString:_minorTextField.text];
    
    if (_region) {
        [_locationManager startMonitoringForRegion:_region];
    }
    
    _region = nil;
    if(self.uuid && self.major && self.minor)
    {
        _region = [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid major:[self.major shortValue] minor:[self.minor shortValue] identifier:BeaconIdentifier];
    }
    else if(self.uuid && self.major)
    {
        _region = [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid major:[self.major shortValue]  identifier:BeaconIdentifier];
    }
    else if(self.uuid)
    {
        _region = [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid identifier:BeaconIdentifier];
    }
    
    [_locationManager startMonitoringForRegion:_region];
}
@end
