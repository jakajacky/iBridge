//
//  BLECharacteristicsViewController.h
//  iBridge
//
//  Created by qiuwenqing on 15/11/19.
//  Copyright © 2015年 IVT. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CBCharacteristic;
@class BLECustomService;

@interface BLECharacteristicViewController : UIViewController

- (void)setCharacteristic:(CBCharacteristic *)characteristic service:(BLECustomService *)bleCustomService;

@end
