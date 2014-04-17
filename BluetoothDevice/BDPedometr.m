//
//  BDPedometr.m
//  BluetoothDevice
//
//  Created by jMac on 08.04.14.
//  Copyright (c) 2014 jMac. All rights reserved.
//

#import "BDPedometr.h"
@import CoreBluetooth;

#define NOTIFY_MTU 20

int counter = 0;
BOOL sendingEOM = NO;

struct SRealTimeData
{
    unsigned int walkSteps;
    unsigned int runSteps;
    unsigned int distance;
    unsigned int kcal;
    unsigned int activity_time;
};

struct STotalActivityData
{
    unsigned int walkSteps;
    unsigned int runSteps;
    unsigned int distance;
    unsigned int kcal;
    unsigned int activity_time;
};

@interface BDPedometr () <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *notifyCharacteristic;
@property (nonatomic, readwrite) NSInteger sendDataIndex;
@property (nonatomic, copy) RealTimeDataHandler realTimeDataHandler;
@property (nonatomic) BOOL isNotifying;
@property (nonatomic) BOOL isSubcribed;

@property (nonatomic) struct SRealTimeData realTimeData;

@end

@implementation BDPedometr

- (instancetype)initWithHandler:(RealTimeDataHandler)handler;
{
    if (self = [super init]) {
        
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        
        memset(&_realTimeData, 0, sizeof(struct SRealTimeData));
        self.realTimeDataHandler = handler;
        self.isNotifying = NO;
        self.isSubcribed = NO;
        
    }
    
    return self;
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    NSLog(@"peripheralManagerDidUpdateState");
    
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        self.notifyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"FFE6"] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
        CBMutableCharacteristic *readCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"FFE7"] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
        
        CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"FFE5"] primary:YES];
        
        transferService.characteristics = @[self.notifyCharacteristic, readCharacteristic ];
        
        [self.peripheralManager addService:transferService];
        
        [self start];
        
    }
}

- (void)start
{
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:@"FFF0"]], CBAdvertisementDataLocalNameKey: @"Pedometr simulator"}];
    self.isNotifying = YES;
    if (self.isSubcribed) {
        memset(&_realTimeData, 0, sizeof(struct SRealTimeData));
        [self sendData:[self getRealTimeData]];
    }
}

- (void)stop
{
    [self.peripheralManager stopAdvertising];
    self.isNotifying = NO;
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    
    NSLog(@"didSubscribeToCharacteristic");
    
    self.isSubcribed = YES;
    self.isNotifying = YES;
    [self sendData:[self getRealTimeData]];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"didUnsubscribeFromCharacteristic");
    
    self.isSubcribed = NO;
    
    memset(&_realTimeData, 0, sizeof(struct SRealTimeData));
    self.realTimeDataHandler(@(_realTimeData.walkSteps), @(_realTimeData.runSteps), @(_realTimeData.kcal), @(_realTimeData.distance), @(_realTimeData.activity_time));
    self.isNotifying = NO;
    [self sendData:nil];
}

- (void)sendData:(NSData*)data {
    
    

    
    // end of message?
    if (data == nil) {
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.notifyCharacteristic onSubscribedCentrals:nil];
        
        if (didSend) {
            // It did, so mark it as sent
            sendingEOM = NO;
        }
        // didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
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
            
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.notifyCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                NSLog(@"Sent: EOM");
            }
            
            return;
        }
    }
}
- (NSData*)getRealTimeData
{
    _sendDataIndex = 0;
    _realTimeData.walkSteps += 5;
    _realTimeData.runSteps += 10;
    _realTimeData.kcal += 15;
    _realTimeData.distance += 7;
    _realTimeData.activity_time += 20;
    
    NSData *data = [NSData dataWithBytes:&_realTimeData length:sizeof(struct SRealTimeData)];
    
    self.realTimeDataHandler(@(_realTimeData.walkSteps), @(_realTimeData.runSteps), @(_realTimeData.kcal), @(_realTimeData.distance), @(_realTimeData.activity_time));
    
    return data;
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
    if(self.isNotifying)
    {
        [NSThread sleepForTimeInterval:1];
        [self sendData:[self getRealTimeData]];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"didReceiveReadRequest");
    struct STotalActivityData totalActivityData;
    
    memset(&totalActivityData, 0, sizeof(struct SRealTimeData));
    
    totalActivityData.walkSteps = arc4random() % 2000 + 500;
    totalActivityData.runSteps = arc4random() % 2000 + 500;
    totalActivityData.kcal = arc4random() % 1000 + 500;
    totalActivityData.distance = arc4random() % 15 + 1;
    totalActivityData.activity_time = 20;
    
    request.value = [NSData dataWithBytes:&totalActivityData length:sizeof(struct STotalActivityData)];
    
    [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
}

@end
