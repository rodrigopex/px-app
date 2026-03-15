/* PXDeviceManager — device lifecycle state machine. */

#import <Foundation/Foundation.h>

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
