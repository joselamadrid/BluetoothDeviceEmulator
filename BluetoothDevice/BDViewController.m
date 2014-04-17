//
//  BDViewController.m
//  BluetoothDevice
//
//  Created by jMac on 08.04.14.
//  Copyright (c) 2014 jMac. All rights reserved.
//

#import "BDViewController.h"
#import "BDPedometr.h"

@interface BDViewController ()

@property (strong, nonatomic) BDPedometr *pedometr;

@end

@implementation BDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startPedometr:(id)sender {
    
    self.pedometr = [[BDPedometr alloc] init];
}

- (IBAction)startScale:(id)sender {
}
@end
