//
//  BDPedometrTableViewController.m
//  BluetoothDevice
//
//  Created by jMac on 14.04.14.
//  Copyright (c) 2014 jMac. All rights reserved.
//

#import "BDPedometrTableViewController.h"
#import "BDPedometr.h"

@interface BDPedometrTableViewController ()

@property (strong, nonatomic) BDPedometr *pedometr;
@end

@implementation BDPedometrTableViewController

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
    
    self.pedometr = [[BDPedometr alloc] initWithHandler:^(NSNumber* walkSteps, NSNumber* runSteps, NSNumber* distance, NSNumber* kcal, NSNumber* activity_time){
        self.walkStepsLabel.text = [walkSteps stringValue];
        self.runStepsLabel.text = [runSteps stringValue];
        self.distanceLabel.text = [distance stringValue];
        self.kcalLabel.text = [kcal stringValue];
        self.activityTimeLabel.text = [activity_time stringValue];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startButton:(UIButton *)sender {
    
    [self.pedometr start];
}

- (IBAction)stopButton:(UIButton *)sender {
    
    [self.pedometr stop];
}
@end
