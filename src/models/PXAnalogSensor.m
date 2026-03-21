/* PXAnalogSensor — level 2, adds calibration. */

#import "PXAnalogSensor.h"

enum PXSensorType {
        PXSensorTypeBase = 0,
        PXSensorTypeAnalog = 1,
        PXSensorTypeTemperature = 2,
        PXSensorTypeHumidity = 3,
        PXSensorTypePressure = 4,
        PXSensorTypeBarometer = 5
};

@implementation PXAnalogSensor

- (id)initWithId:(int)sensorId calibration:(int)offset {
        self = [super initWithId:sensorId];
        _rawValue = 0;
        _calibrationOffset = offset;
        return self;
}

- (int)readRaw {
        _rawValue = _rawValue + 5;
        _sampleCount = _sampleCount + 1;
        return _rawValue;
}

- (int)calibratedValue {
        return _rawValue + _calibrationOffset;
}

- (int)sensorType {
        return PXSensorTypeAnalog;
}

- (OZString *)typeName {
        return @"AnalogSensor";
}

@end
