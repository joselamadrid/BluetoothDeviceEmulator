//
//  BDPedometrTableViewController.h
//  BluetoothDevice
//
//  Created by jMac on 14.04.14.
//  Copyright (c) 2014 jMac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BDPedometrTableViewController : UITableViewController

@property (strong, nonatomic) IBOutlet UILabel *walkStepsLabel;
@property (strong, nonatomic) IBOutlet UILabel *runStepsLabel;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *kcalLabel;
@property (strong, nonatomic) IBOutlet UILabel *activityTimeLabel;

- (IBAction)startButton:(UIButton *)sender;
- (IBAction)stopButton:(UIButton *)sender;
- (IBAction)powerOff:(UIButton *)sender;
@end
