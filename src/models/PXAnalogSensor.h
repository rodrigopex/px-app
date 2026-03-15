/* PXAnalogSensor — level 2: PXSensorBase → PXAnalogSensor. */

#import "models/PXSensorBase.h"

@interface PXAnalogSensor : PXSensorBase {
        int _rawValue;
        int _calibrationOffset;
}

- (id)initWithId:(int)sensorId calibration:(int)offset;
- (int)readRaw;
- (int)calibratedValue;

@end
