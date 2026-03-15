/* PXPressureSensor — level 3, adds pressure scaling. */

#import "PXPressureSensor.h"

@implementation PXPressureSensor

- (id)initWithId:(int)sensorId calibration:(int)offset scale:(int)scale {
        self = [super initWithId:sensorId calibration:offset];
        _pressureScale = scale;
        return self;
}

- (int)pressureReading {
        [self readRaw];
        return [self calibratedValue] * _pressureScale;
}

- (OZString *)typeName {
        return @"PressureSensor";
}

@end
