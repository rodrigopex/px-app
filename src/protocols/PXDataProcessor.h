/* PXDataProcessor — protocol for data processing pipeline stages. */

#import <Foundation/Foundation.h>

@protocol PXDataProcessor <OZProtocol>

- (int)processValue:(int)value fromSensor:(int)sensorId;
- (OZString *)processorName;

@end
