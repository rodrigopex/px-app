/* PXSensorProtocol — protocol for all sensor types. */

#import <Foundation/Foundation.h>

@protocol PXSensorProtocol <OZProtocol>

- (int)sensorId;
- (int)readValue;
- (OZString *)name;

@end
