/* PXMovingAverageFilter — smooths sensor readings with a moving average. */

#import <Foundation/Foundation.h>
#import "protocols/PXDataProcessor.h"

@interface PXMovingAverageFilter : OZObject <PXDataProcessor> {
        int _sum;
        int _count;
        int _windowSize;
}

- (id)initWithWindowSize:(int)windowSize;

@end
