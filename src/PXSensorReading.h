/* PXSensorReading — immutable value object for a single sensor measurement. */

#import <Foundation/Foundation.h>

@interface PXSensorReading : OZObject {
        int _sensorId;
        int _value;
        int _timestamp;
}

- (id)initWithSensorId:(int)sensorId value:(int)value timestamp:(int)timestamp;
- (int)sensorId;
- (int)value;
- (int)timestamp;

@end
