/* PXSensorRegistry — manages a collection of sensors. */

#import <Foundation/Foundation.h>
#import "protocols/PXSensorProtocol.h"

@interface PXSensorRegistry : OZObject {
        OZArray *_sensors;
}

- (id)initWithSensors:(OZArray *)sensors;
- (int)sensorCount;
- (void)readAll;

@end
