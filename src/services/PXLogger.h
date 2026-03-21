/* PXLogger — structured logging with severity levels. */

#import <Foundation/Foundation.h>

enum PXLogLevel {
        PXLogLevelDebug = 0,
        PXLogLevelInfo = 1,
        PXLogLevelWarn = 2,
        PXLogLevelError = 3
};

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
