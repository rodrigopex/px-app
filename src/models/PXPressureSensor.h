/* PXPressureSensor — level 3: PXAnalogSensor → PXPressureSensor. */

#import "models/PXAnalogSensor.h"

@interface PXPressureSensor : PXAnalogSensor {
        int _pressureScale;
}

- (id)initWithId:(int)sensorId calibration:(int)offset scale:(int)scale;
- (int)pressureReading;
- (int)sensorType;

@end
