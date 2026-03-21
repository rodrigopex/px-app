/* PXSensorBase — base class for sensor hierarchy (level 1: OZObject → PXSensorBase). */

#import <Foundation/Foundation.h>

enum PXSensorType {
        PXSensorTypeBase = 0,
        PXSensorTypeAnalog = 1,
        PXSensorTypeTemperature = 2,
        PXSensorTypeHumidity = 3,
        PXSensorTypePressure = 4,
        PXSensorTypeBarometer = 5
};

@interface PXSensorBase : OZObject {
        int _sensorId;
        int _sampleCount;
}

- (id)initWithId:(int)sensorId;
- (int)sensorId;
- (int)sampleCount;
- (int)sensorType;
- (OZString *)typeName;

@end
