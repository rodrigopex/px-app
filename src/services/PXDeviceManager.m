/* PXDeviceManager — state machine with switch/case + enum + @synchronized. */

#import "PXDeviceManager.h"

@implementation PXDeviceManager

- (id)init {
        self = [super init];
        _state = PXDeviceStateIdle;
        _errorCount = 0;
        return self;
}

- (int)state {
        return _state;
}

- (void)start {
        @synchronized(self) {
                switch (_state) {
                        case PXDeviceStateIdle:
                                _state = PXDeviceStateInitializing;
                                OZLog("    [DeviceManager] initializing...\n");
                                _state = PXDeviceStateRunning;
                                OZLog("    [DeviceManager] running\n");
                                break;
                        case PXDeviceStateStopped:
                                _state = PXDeviceStateInitializing;
                                OZLog("    [DeviceManager] restarting...\n");
                                _state = PXDeviceStateRunning;
                                OZLog("    [DeviceManager] running\n");
                                break;
                        default:
                                _errorCount = _errorCount + 1;
                                OZLog("    [DeviceManager] ERROR: already running\n");
                                break;
                }
        }
}

- (void)stop {
        @synchronized(self) {
                switch (_state) {
                        case PXDeviceStateRunning:
                                _state = PXDeviceStateStopped;
                                OZLog("    [DeviceManager] stopped\n");
                                break;
                        default:
                                _errorCount = _errorCount + 1;
                                OZLog("    [DeviceManager] ERROR: not running\n");
                                break;
                }
        }
}

- (void)reportStatus {
        switch (_state) {
                case PXDeviceStateIdle:
                        OZLog("    status: idle\n");
                        break;
                case PXDeviceStateInitializing:
                        OZLog("    status: initializing\n");
                        break;
                case PXDeviceStateRunning:
                        OZLog("    status: running\n");
                        break;
                case PXDeviceStateStopped:
                        OZLog("    status: stopped\n");
                        break;
                default:
                        OZLog("    status: unknown\n");
                        break;
        }
        OZLog("    errors: %d\n", _errorCount);
}

@end
