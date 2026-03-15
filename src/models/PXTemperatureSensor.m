/* PXTemperatureSensor — first protocol conformer. */

#import "PXTemperatureSensor.h"

@implementation PXTemperatureSensor

- (id)initWithId:(int)sensorId {
        self = [super init];
        _sensorId = sensorId;
        _currentTemp = 22;
        return self;
}

- (int)sensorId {
        return _sensorId;
}

- (int)readValue {
        /* Simulate temperature reading — increment by 1 each call */
        _currentTemp = _currentTemp + 1;
        return _currentTemp;
}

- (OZString *)name {
        return @"TemperatureSensor";
}

@end
