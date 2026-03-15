/* PXSystemStatus — cross-file header dependencies, multi-arg init. */

#import "PXSystemStatus.h"

@implementation PXSystemStatus

- (id)initWithManager:(PXDeviceManager *)mgr
             registry:(PXSensorRegistry *)registry
            publisher:(PXZbusPublisher *)publisher
               logger:(PXLogger *)logger {
        self = [super init];
        _mgr = mgr;
        _registry = registry;
        _publisher = publisher;
        _logger = logger;
        return self;
}

- (void)printStatus {
        OZLog("  === System Status ===\n");
        [_mgr reportStatus];
        OZLog("  sensors: %d\n", [_registry sensorCount]);
        OZLog("  publishes: %d\n", [_publisher publishCount]);
        OZLog("  last value: %d\n", [_publisher lastPublishedValue]);
        OZLog("  log messages: %d\n", [_logger messageCount]);
        [_logger info:@"status reported"];
}

@end
