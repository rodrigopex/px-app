/* PXSensorRegistry — collection management with OZArray and for-in. */

#import "PXSensorRegistry.h"

@implementation PXSensorRegistry

- (id)initWithSensors:(OZArray *)sensors {
        self = [super init];
        _sensors = sensors;
        return self;
}

- (int)sensorCount {
        return [_sensors count];
}

- (void)readAll {
        for (id obj in _sensors) {
                id<PXSensorProtocol> sensor = (id<PXSensorProtocol>)obj;
                OZString *sensorName = [sensor name];
                OZLog("    %s[%d] = %d\n",
                      [sensorName cString], [sensor sensorId], [sensor readValue]);
        }
}

@end
