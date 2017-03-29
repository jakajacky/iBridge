//
//  BLECustomServiceViewController.h
//  iBridge
//
//  Created by qiuwenqing on 15/11/19.
//  Copyright © 2015年 IVT. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CBPeripheral;

@interface BLECustomServiceViewController : UIViewController

- (void)setPeripheral:(CBPeripheral *)peripheral serviceUuidString:(NSString *)serviceUuidString;

@end
