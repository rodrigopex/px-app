/* PXAnalogSensor — level 2, adds calibration. */

#import "PXAnalogSensor.h"

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
