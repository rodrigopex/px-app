/* PXSensorBase — level 1 of inheritance hierarchy. */

#import "PXSensorBase.h"

@implementation PXSensorBase

- (id)initWithId:(int)sensorId {
        self = [super init];
        _sensorId = sensorId;
        _sampleCount = 0;
        return self;
}

- (int)sensorId {
        return _sensorId;
}

- (int)sampleCount {
        return _sampleCount;
}

- (OZString *)typeName {
        return @"SensorBase";
}

@end
