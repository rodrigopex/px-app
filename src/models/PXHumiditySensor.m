/* PXHumiditySensor — second protocol conformer for multi-class dispatch. */

#import "PXHumiditySensor.h"
#import "PXSensorBase.h"

@implementation PXHumiditySensor

- (id)initWithId:(int)sensorId {
        self = [super init];
        _sensorId = sensorId;
        _currentHumidity = 55;
        return self;
}

- (int)sensorId {
        return _sensorId;
}

- (int)readValue {
        /* Simulate humidity — decrease by 2 each call */
        _currentHumidity = _currentHumidity - 2;
        return _currentHumidity;
}

- (int)sensorType {
        return PXSensorTypeHumidity;
}

- (OZString *)name {
        return @"HumiditySensor";
}

@end
