/* PXZbusPublisher — publishes sensor data to zbus channel. */

#import <Foundation/Foundation.h>

@interface PXZbusPublisher : OZObject {
        int _publishCount;
        int _lastPublishedValue;
}

@property (nonatomic, assign) int publishCount;
@property (nonatomic, assign) int lastPublishedValue;

- (id)init;
- (int)publishSensorId:(int)sensorId value:(int)value timestamp:(int)ts;
- (void)publishSensorId:(int)sensorId
                  value:(int)value
              timestamp:(int)ts
             completion:(void (^)(int status))callback;

@end
