/* PXDeviceManager — device lifecycle state machine. */

#import <Foundation/Foundation.h>

enum PXDeviceState {
        PXDeviceStateIdle = 0,
        PXDeviceStateInitializing = 1,
        PXDeviceStateRunning = 2,
        PXDeviceStateStopped = 3
};

@interface PXDeviceManager : OZObject {
        int _state;
        int _errorCount;
}

- (id)init;
- (int)state;
- (void)start;
- (void)stop;
- (void)reportStatus;

@end
