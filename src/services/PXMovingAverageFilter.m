/* PXMovingAverageFilter — running average over a window of readings. */

#import "PXMovingAverageFilter.h"

@implementation PXMovingAverageFilter

- (id)initWithWindowSize:(int)windowSize {
        self = [super init];
        _sum = 0;
        _count = 0;
        _windowSize = windowSize;
        return self;
}

- (int)processValue:(int)value fromSensor:(int)sensorId {
        _sum = _sum + value;
        _count = _count + 1;
        if (_count > _windowSize) {
                /* Approximate: just divide by window size */
                _sum = _sum - (_sum / _count);
                _count = _windowSize;
        }
        return _sum / _count;
}

- (OZString *)processorName {
        return @"MovingAverage";
}

@end
