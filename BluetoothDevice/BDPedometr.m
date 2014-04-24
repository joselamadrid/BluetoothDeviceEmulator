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
@property (nonatomic) BOOL isRunning;

@property (nonatomic) struct SRealTimeData realTimeData;
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation BDPedometr

- (instancetype)initWithHandler:(RealTimeDataHandler)handler;
{
    if (self = [super init]) {
        memset(&_realTimeData, 0, sizeof(struct SRealTimeData));
        self.realTimeDataHandler = handler;
        self.isNotifying = NO;
        self.isSubcribed = NO;
        self.isRunning = NO;
        
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        
        [self start];
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementVal) userInfo:nil repeats:YES];
        
    }
    
    return self;
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    NSLog(@"peripheralManagerDidUpdateState");
    
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    
    if(!self.peripheralManager)
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    self.notifyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"FFE6"] properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyNotifyEncryptionRequired value:nil permissions:CBAttributePermissionsReadEncryptionRequired];
    CBMutableCharacteristic *readCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"FFE7"] properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyNotifyEncryptionRequired value:nil permissions:CBAttributePermissionsReadEncryptionRequired];
    
    CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"FFE5"] primary:YES];
    
    transferService.characteristics = @[self.notifyCharacteristic, readCharacteristic ];
    
    [self.peripheralManager addService:transferService];
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:@"FFF0"]], CBAdvertisementDataLocalNameKey: @"Pedometr simulator"}];

}

- (void)start
{
    if(!self.peripheralManager)
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    self.isNotifying = YES;
    self.isRunning = YES;
}

- (void)incrementVal
{
    if(self.isRunning)
    {
        _realTimeData.walkSteps += arc4random() % 10 + 5;
        _realTimeData.runSteps += arc4random() % 15 + 5;
        _realTimeData.kcal += arc4random() % 20 + 10;
        _realTimeData.distance += arc4random() % 20 + 10;
        _realTimeData.activity_time += arc4random() % 20 + 10;
        
        self.realTimeDataHandler(@(_realTimeData.walkSteps), @(_realTimeData.runSteps), @(_realTimeData.kcal), @(_realTimeData.distance), @(_realTimeData.activity_time));
        
        if(self.isNotifying)
            [self sendData:[self getRealTimeData]];
    }
}

- (void)stop
{
    memset(&_realTimeData, 0, sizeof(struct SRealTimeData));
    self.realTimeDataHandler(@(_realTimeData.walkSteps), @(_realTimeData.runSteps), @(_realTimeData.kcal), @(_realTimeData.distance), @(_realTimeData.activity_time));
    self.isNotifying = NO;
    self.isRunning = NO;
}

- (void)powerOff
{
    self.peripheralManager = nil;
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    
    NSLog(@"didSubscribeToCharacteristic");
    
    self.isSubcribed = YES;
    self.isNotifying = YES;
    [self sendData:[self getRealTimeData]];
}

- (NSData*)getRealTimeData
{
    _sendDataIndex = 0;
    
    
    NSData *data = [NSData dataWithBytes:&_realTimeData length:sizeof(struct SRealTimeData)];
    
    return data;
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"didUnsubscribeFromCharacteristic");
    
    self.isSubcribed = NO;

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

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    
    //NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"didReceiveReadRequest");
    struct STotalActivityData totalActivityData;
    
    [NSThread sleepForTimeInterval:arc4random() % 15 + 1];
    
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
