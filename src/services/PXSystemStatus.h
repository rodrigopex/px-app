/* PXSystemStatus — aggregates status from multiple subsystems.
 * Tests cross-file #import dependencies and forward declarations. */

#import <Foundation/Foundation.h>
#import "services/PXDeviceManager.h"
#import "services/PXSensorRegistry.h"
#import "services/PXZbusPublisher.h"
#import "services/PXLogger.h"

@interface PXSystemStatus : OZObject {
        PXDeviceManager *_mgr;
        PXSensorRegistry *_registry;
        PXZbusPublisher *_publisher;
        PXLogger *_logger;
}

- (id)initWithManager:(PXDeviceManager *)mgr
             registry:(PXSensorRegistry *)registry
            publisher:(PXZbusPublisher *)publisher
               logger:(PXLogger *)logger;
- (void)printStatus;

@end
