/* PXSensorReading — value object with ivars, init with args, getters. */

#import "PXSensorReading.h"

@implementation PXSensorReading

- (id)initWithSensorId:(int)sensorId value:(int)value timestamp:(int)timestamp {
        self = [super init];
        _sensorId = sensorId;
        _value = value;
        _timestamp = timestamp;
        return self;
}

- (int)sensorId {
        return _sensorId;
}

- (int)value {
        return _value;
}

- (int)timestamp {
        return _timestamp;
}

@end
