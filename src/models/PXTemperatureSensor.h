/* PXTemperatureSensor — temperature sensor conforming to PXSensorProtocol. */

#import <Foundation/Foundation.h>
#import "protocols/PXSensorProtocol.h"

@interface PXTemperatureSensor : OZObject <PXSensorProtocol> {
        int _sensorId;
        int _currentTemp;
}

- (id)initWithId:(int)sensorId;
- (int)sensorType;
- (OZString *)name;

@end
