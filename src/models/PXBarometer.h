/* PXBarometer — level 4: PXPressureSensor → PXBarometer. */

#import "models/PXPressureSensor.h"

@interface PXBarometer : PXPressureSensor {
        int _altitudeEstimate;
}

- (id)initWithId:(int)sensorId;
- (int)altitude;

@end
