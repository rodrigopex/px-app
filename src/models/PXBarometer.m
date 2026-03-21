/* PXBarometer — level 4 (deepest), estimates altitude from pressure. */

#import "PXBarometer.h"

@implementation PXBarometer

- (id)initWithId:(int)sensorId {
        self = [super initWithId:sensorId calibration:10 scale:2];
        _altitudeEstimate = 0;
        return self;
}

- (int)altitude {
        int pressure = [self pressureReading];
        /* Simple altitude estimate: 1013 hPa at sea level, -12m per hPa */
        _altitudeEstimate = (1013 - pressure) * 12;
        return _altitudeEstimate;
}

- (int)sensorType {
        return PXSensorTypeBarometer;
}

- (OZString *)typeName {
        return @"Barometer";
}

@end
