//
//  BDScale.m
//  BluetoothDevice
//
//  Created by jMac on 08.04.14.
//  Copyright (c) 2014 jMac. All rights reserved.
//

#import "BDScale.h"
@import CoreBluetooth;

struct SScalesData
{
    unsigned int weight;
    unsigned int body_fat;
    unsigned int body_water;
    unsigned int bmi;
    unsigned int muscule_mass;
    unsigned int bone_mass;
    unsigned int visceral_fat;
    unsigned int bmr;
};

#define NOTIFY_MTU 20

@interface BDScale () <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *notifyCharacteristic;
@property (nonatomic, readwrite) NSInteger sendDataIndex;

//@property (nonatomic) struct SRealTimeData realTimeData;

@end

@implementation BDScale

- (instancetype)init
{
    if (self = [super init]) {
        
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        
        //memset(&_realTimeData, 0, sizeof(struct SRealTimeData));
        
    }
    
    return self;
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    NSLog(@"peripheralManagerDidUpdateState");
    
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        self.notifyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"AAE6"] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
        
        CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"AAE5"] primary:YES];
        
        transferService.characteristics = @[self.notifyCharacteristic];
        
        [self.peripheralManager addService:transferService];
        
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:@"AAA0"]], CBAdvertisementDataLocalNameKey: @"Scales simulator"}];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    
    NSLog(@"didSubscribeToCharacteristic");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"didUnSubscribeToCharacteristic");
    
    [self sendData:nil];
}

- (void)notifyWeight:(NSNumber*)weight
{
    struct SScalesData scalesData;
    scalesData.weight = [weight intValue];
    scalesData.body_fat = arc4random() % 20 + 10;
    scalesData.body_water = arc4random() % 20 + 10;
    scalesData.bmi = arc4random() % 20 + 5;
    scalesData.muscule_mass = arc4random() % 2 + 1;
    scalesData.bone_mass = arc4random() % 2 + 1;
    scalesData.visceral_fat = arc4random() % 10 + 1;
    scalesData.bmr = arc4random() % 15 + 5;

    
    NSData *data = [NSData dataWithBytes:&scalesData length:sizeof(struct SScalesData)];
    [self sendData:data];
}

- (void)sendData:(NSData*)data {
    
    self.sendDataIndex = 0;
    
    
    // end of message?
    if (data == nil) {
        [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.notifyCharacteristic onSubscribedCentrals:nil];

        return;
    }
    
    // We're sending data
    // Is there any left to send?
    if (self.sendDataIndex >= data.length) {
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    BOOL didSend = YES;
    
    while (didSend) {
        // Work out how big it should be
        NSInteger amountToSend = data.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:data.bytes+self.sendDataIndex length:amountToSend];
        
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.notifyCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }
        
        //NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        //NSLog(@"Sent: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.sendDataIndex >= data.length) {
            
            // Set this so if the send fails, we'll send it next time
            
            [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.notifyCharacteristic onSubscribedCentrals:nil];
            
            
            return;
        }
    }
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
}

@end
