/* PXLogger — structured logging with OZLog, string formatting, class methods. */

#import "PXLogger.h"

static PXLogger *_sharedLogger;

@implementation PXLogger

+ (void)initialize {
        _sharedLogger = [[PXLogger alloc] init];
}

+ (instancetype)sharedInstance {
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
                        OZLog("[DBG] %s\n", [msg cString]);
                        break;
                case PXLogLevelInfo:
                        OZLog("[INF] %s\n", [msg cString]);
                        break;
                case PXLogLevelWarn:
                        OZLog("[WRN] %s\n", [msg cString]);
                        break;
                case PXLogLevelError:
                        OZLog("[ERR] %s\n", [msg cString]);
                        break;
                default:
                        OZLog("[???] %s\n", [msg cString]);
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
