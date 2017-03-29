//
//  BLEHRViewController.h
//  iBridge
//
//  Created by qiuwenqing on 15/11/17.
//  Copyright © 2015年 IVT. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CBPeripheral;

@interface BLEHRViewController : UIViewController

- (void)setPeripheral:(CBPeripheral *)peripheral;

@end
