/* PXAppConfig — singleton configuration manager for the sensor monitoring system. */

#import <Foundation/Foundation.h>

@interface PXAppConfig : OZObject <SingletonProtocol> {
        int _sampleIntervalMs;
        int _thresholdHigh;
        int _thresholdLow;
        int _maxSensorCount;
}

@property (nonatomic, assign) int sampleIntervalMs;
@property (nonatomic, assign) int thresholdHigh;
@property (nonatomic, assign) int thresholdLow;
@property (nonatomic, assign) int maxSensorCount;

+ (void)initialize;
+ (instancetype)sharedInstance;

@end
