/* PXLogger — structured logging with severity levels.
 * Log levels: 0=debug, 1=info, 2=warn, 3=error (enum in .m file) */

#import <Foundation/Foundation.h>

@interface PXLogger : OZObject {
        int _minLevel;
        int _messageCount;
}

+ (void)initialize;
+ (PXLogger *)shared;
- (void)setMinLevel:(int)level;
- (void)logLevel:(int)level message:(OZString *)msg;
- (void)info:(OZString *)msg;
- (void)warn:(OZString *)msg;
- (void)error:(OZString *)msg;
- (int)messageCount;

@end
