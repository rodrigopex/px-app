/* PXZbusPublisher — zbus C interop + non-capturing blocks. */

#import "PXZbusPublisher.h"
#include <zephyr/kernel.h>
#include <zephyr/zbus/zbus.h>

struct px_sensor_msg {
        int sensor_id;
        int value;
        int timestamp;
};

ZBUS_CHAN_DEFINE(px_sensor_chan,
                struct px_sensor_msg,
                NULL, NULL,
                ZBUS_OBSERVERS_EMPTY,
                ZBUS_MSG_INIT(0));

@implementation PXZbusPublisher

@synthesize publishCount = _publishCount;
@synthesize lastPublishedValue = _lastPublishedValue;

- (id)init {
        self = [super init];
        _publishCount = 0;
        _lastPublishedValue = 0;
        return self;
}

- (int)publishSensorId:(int)sensorId value:(int)value timestamp:(int)ts {
        struct px_sensor_msg msg;
        msg.sensor_id = sensorId;
        msg.value = value;
        msg.timestamp = ts;

        int err = zbus_chan_pub(&px_sensor_chan, &msg, K_NO_WAIT);
        if (err == 0) {
                _publishCount = _publishCount + 1;
                _lastPublishedValue = value;
        }
        return err;
}

- (void)publishSensorId:(int)sensorId
                  value:(int)value
              timestamp:(int)ts
             completion:(void (^)(int status))callback {
        int err = [self publishSensorId:sensorId value:value timestamp:ts];
        callback(err);
}

@end
