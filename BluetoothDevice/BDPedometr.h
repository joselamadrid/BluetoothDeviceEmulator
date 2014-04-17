//
//  BDPedometr.h
//  BluetoothDevice
//
//  Created by jMac on 08.04.14.
//  Copyright (c) 2014 jMac. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^RealTimeDataHandler)(NSNumber* walkSteps, NSNumber* runSteps, NSNumber* distance, NSNumber* kcal, NSNumber* activity_time);
@interface BDPedometr : NSObject

- (instancetype)initWithHandler:(RealTimeDataHandler)handler;

- (void)start;
- (void)stop;

@end
