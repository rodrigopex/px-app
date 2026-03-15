/* PXHumiditySensor — humidity sensor conforming to PXSensorProtocol. */

#import <Foundation/Foundation.h>
#import "protocols/PXSensorProtocol.h"

@interface PXHumiditySensor : OZObject <PXSensorProtocol> {
        int _sensorId;
        int _currentHumidity;
}

- (id)initWithId:(int)sensorId;
- (OZString *)name;

@end
