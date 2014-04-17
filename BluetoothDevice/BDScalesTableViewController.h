//
//  BDScalesTableViewController.h
//  BluetoothDevice
//
//  Created by jMac on 14.04.14.
//  Copyright (c) 2014 jMac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BDScalesTableViewController : UITableViewController

@property (strong, nonatomic) IBOutlet UILabel *weightValueLabel;
- (IBAction)standOnTouched:(UIButton *)sender;
- (IBAction)standOffTouched:(UIButton *)sender;
@end
