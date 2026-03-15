/* PXThresholdFilter — clamps values within low/high bounds. */

#import "PXThresholdFilter.h"

@implementation PXThresholdFilter

- (id)initWithLow:(int)low high:(int)high {
        self = [super init];
        _low = low;
        _high = high;
        return self;
}

- (int)processValue:(int)value fromSensor:(int)sensorId {
        if (value < _low) {
                return _low;
        }
        if (value > _high) {
                return _high;
        }
        return value;
}

- (OZString *)processorName {
        return @"ThresholdFilter";
}

@end
