/* PXPressureSensor — level 3, adds pressure scaling. */

#import "PXPressureSensor.h"

enum PXSensorType {
        PXSensorTypeBase = 0,
        PXSensorTypeAnalog = 1,
        PXSensorTypeTemperature = 2,
        PXSensorTypeHumidity = 3,
        PXSensorTypePressure = 4,
        PXSensorTypeBarometer = 5
};

@implementation PXPressureSensor

- (id)initWithId:(int)sensorId calibration:(int)offset scale:(int)scale {
        self = [super initWithId:sensorId calibration:offset];
        _pressureScale = scale;
        return self;
}

- (int)pressureReading {
        [self readRaw];
        return [self calibratedValue] * _pressureScale;
}

- (int)sensorType {
        return PXSensorTypePressure;
}

- (OZString *)typeName {
        return @"PressureSensor";
}

@end
