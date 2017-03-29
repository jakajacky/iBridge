//
//  BLEGATTViewController.h
//  iBridgeTestDemo
//
//  Created by Michael Zu on 14-2-13.
//  Copyright (c) 2014年 IVT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEManager.h"

@interface BLEGATTViewController : UIViewController

- (void)setPeripheral:(nonnull CBPeripheral *)peripheral service:(nonnull NSString *)serviceUuid;

@end
