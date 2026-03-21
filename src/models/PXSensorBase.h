/* PXSensorBase — base class for sensor hierarchy (level 1: OZObject → PXSensorBase). */

#import <Foundation/Foundation.h>

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
