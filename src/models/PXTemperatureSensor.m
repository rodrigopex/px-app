/* PXTemperatureSensor — first protocol conformer. */

#import "PXTemperatureSensor.h"
#import "PXSensorBase.h"

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

- (int)sensorType {
        return PXSensorTypeTemperature;
}

- (OZString *)name {
        return @"TemperatureSensor";
}

@end
