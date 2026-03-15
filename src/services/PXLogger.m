/* PXLogger — structured logging with OZLog, string formatting, class methods. */

#import "PXLogger.h"

enum PXLogLevel {
        PXLogLevelDebug = 0,
        PXLogLevelInfo = 1,
        PXLogLevelWarn = 2,
        PXLogLevelError = 3
};

static PXLogger *_sharedLogger;

@implementation PXLogger

+ (void)initialize {
        _sharedLogger = [[PXLogger alloc] init];
}

+ (PXLogger *)shared {
        return _sharedLogger;
}

- (id)init {
        self = [super init];
        _minLevel = PXLogLevelInfo;
        _messageCount = 0;
        return self;
}

- (void)setMinLevel:(int)level {
        _minLevel = level;
}

- (void)logLevel:(int)level message:(OZString *)msg {
        if (level < _minLevel) {
                return;
        }
        _messageCount = _messageCount + 1;

        switch (level) {
                case PXLogLevelDebug:
                        OZLog("[DBG] %s\n", [msg cStr]);
                        break;
                case PXLogLevelInfo:
                        OZLog("[INF] %s\n", [msg cStr]);
                        break;
                case PXLogLevelWarn:
                        OZLog("[WRN] %s\n", [msg cStr]);
                        break;
                case PXLogLevelError:
                        OZLog("[ERR] %s\n", [msg cStr]);
                        break;
                default:
                        OZLog("[???] %s\n", [msg cStr]);
                        break;
        }
}

- (void)info:(OZString *)msg {
        [self logLevel:PXLogLevelInfo message:msg];
}

- (void)warn:(OZString *)msg {
        [self logLevel:PXLogLevelWarn message:msg];
}

- (void)error:(OZString *)msg {
        [self logLevel:PXLogLevelError message:msg];
}

- (int)messageCount {
        return _messageCount;
}

@end
