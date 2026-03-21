/* PXLogger — structured logging with severity levels. */

#import <Foundation/Foundation.h>

@interface PXLogger : OZObject <SingletonProtocol> {
        int _minLevel;
        int _messageCount;
}

+ (void)initialize;
+ (instancetype)sharedInstance;
- (void)setMinLevel:(int)level;
- (void)logLevel:(int)level message:(OZString *)msg;
- (void)info:(OZString *)msg;
- (void)warn:(OZString *)msg;
- (void)error:(OZString *)msg;
- (int)messageCount;

@end
