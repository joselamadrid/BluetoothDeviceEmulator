//
//  BDScalesTableViewController.m
//  BluetoothDevice
//
//  Created by jMac on 14.04.14.
//  Copyright (c) 2014 jMac. All rights reserved.
//

#import "BDScalesTableViewController.h"
#import "BDScale.h"

@interface BDScalesTableViewController ()

@property (strong, nonatomic) BDScale *scales;

@end

@implementation BDScalesTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scales = [[BDScale alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)standOnTouched:(UIButton *)sender {
    
    NSNumber *weight = @(arc4random() % 3 + 84);
    self.weightValueLabel.text = [NSString stringWithFormat:@"%@ Kg", weight];
    
    [self.scales notifyWeight:weight];
    
}

- (IBAction)standOffTouched:(UIButton *)sender {
    
    self.weightValueLabel.text = @"0.0 Kg";
}
@end
