/* PXAppConfig — singleton with properties.
 * Exercises: SingletonProtocol, @property, @synthesize, file-scope static. */

#import "PXAppConfig.h"

static PXAppConfig *_sharedConfig;

@implementation PXAppConfig

@synthesize sampleIntervalMs = _sampleIntervalMs;
@synthesize thresholdHigh = _thresholdHigh;
@synthesize thresholdLow = _thresholdLow;
@synthesize maxSensorCount = _maxSensorCount;

+ (void)initialize {
        _sharedConfig = [[PXAppConfig alloc] init];
}

+ (instancetype)sharedInstance {
        return _sharedConfig;
}

- (id)init {
        self = [super init];
        _sampleIntervalMs = 1000;
        _thresholdHigh = 80;
        _thresholdLow = 20;
        _maxSensorCount = 4;
        return self;
}

@end
