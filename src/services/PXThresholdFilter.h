/* PXThresholdFilter — clamps sensor values to configured thresholds. */

#import <Foundation/Foundation.h>
#import "protocols/PXDataProcessor.h"

@interface PXThresholdFilter : OZObject <PXDataProcessor> {
        int _low;
        int _high;
}

- (id)initWithLow:(int)low high:(int)high;

@end
