/* PXSensorBase — level 1 of inheritance hierarchy. */

#import "PXSensorBase.h"

enum PXSensorType {
        PXSensorTypeBase = 0,
        PXSensorTypeAnalog = 1,
        PXSensorTypeTemperature = 2,
        PXSensorTypeHumidity = 3,
        PXSensorTypePressure = 4,
        PXSensorTypeBarometer = 5
};

@implementation PXSensorBase

- (id)initWithId:(int)sensorId {
        self = [super init];
        _sensorId = sensorId;
        _sampleCount = 0;
        return self;
}

- (int)sensorId {
        return _sensorId;
}

- (int)sampleCount {
        return _sampleCount;
}

- (int)sensorType {
        return PXSensorTypeBase;
}

- (OZString *)typeName {
        return @"SensorBase";
}

@end
