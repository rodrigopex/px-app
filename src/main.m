/* Step 13 — Slab auto-count verification. */

#import "services/PXAppConfig.h"
#import "services/PXSensorRegistry.h"
#import "services/PXMovingAverageFilter.h"
#import "services/PXThresholdFilter.h"
#import "services/PXDeviceManager.h"
#import "services/PXZbusPublisher.h"
#import "services/PXLogger.h"
#import "services/PXSystemStatus.h"
#import "PXSensorReading.h"
#import "models/PXTemperatureSensor.h"
#import "models/PXHumiditySensor.h"
#import "models/PXSensorBase.h"
#import "models/PXAnalogSensor.h"
#import "models/PXPressureSensor.h"
#import "models/PXBarometer.h"
#include <zephyr/kernel.h>

static int _blockStatus;

int main(void) {
        PXLogger *log = [PXLogger shared];

        [log info:@"px-app booted"];

        /* === Slab exhaustion test === */
        OZLog("  === Slab exhaustion test ===\n");

        PXSensorReading *r1 = [[PXSensorReading alloc] initWithSensorId:1 value:10 timestamp:0];
        OZLog("  r1 alloc: %s\n", r1 != nil ? "OK" : "NULL");

        PXSensorReading *r2 = [[PXSensorReading alloc] initWithSensorId:2 value:20 timestamp:0];
        OZLog("  r2 alloc: %s\n", r2 != nil ? "OK" : "NULL");

        PXSensorReading *r3 = [[PXSensorReading alloc] initWithSensorId:3 value:30 timestamp:0];
        OZLog("  r3 alloc: %s\n", r3 != nil ? "OK" : "NULL");

        if (r1 != nil) {
                OZLog("  r1: sensor=%d value=%d\n", [r1 sensorId], [r1 value]);
        }
        if (r2 != nil) {
                OZLog("  r2: sensor=%d value=%d\n", [r2 sensorId], [r2 value]);
        }
        if (r3 != nil) {
                OZLog("  r3: sensor=%d value=%d\n", [r3 sensorId], [r3 value]);
        }

        OZLog("  --- releasing r1 ---\n");
        r1 = nil;

        PXSensorReading *r4 = [[PXSensorReading alloc] initWithSensorId:4 value:40 timestamp:0];
        OZLog("  r4 alloc after release: %s\n", r4 != nil ? "OK" : "NULL");
        if (r4 != nil) {
                OZLog("  r4: sensor=%d value=%d\n", [r4 sensorId], [r4 value]);
        }

        /* === Full system === */
        PXDeviceManager *mgr = [[PXDeviceManager alloc] init];
        [mgr start];

        PXTemperatureSensor *temp = [[PXTemperatureSensor alloc] initWithId:1];
        PXHumiditySensor *hum = [[PXHumiditySensor alloc] initWithId:2];
        OZArray<id<PXSensorProtocol>> *sensorArray = @[ temp, hum ];

        PXMovingAverageFilter *avgFilter = [[PXMovingAverageFilter alloc] initWithWindowSize:3];
        PXThresholdFilter *threshFilter = [[PXThresholdFilter alloc]
                initWithLow:20 high:80];
        id<PXDataProcessor> stage1 = (id<PXDataProcessor>)avgFilter;
        id<PXDataProcessor> stage2 = (id<PXDataProcessor>)threshFilter;

        PXZbusPublisher *pub = [[PXZbusPublisher alloc] init];

        int pass = 0;
        while (pass < 2) {
                OZLog("  --- pass %d ---\n", pass);
                for (id sensor in sensorArray) {
                        int raw = [sensor readValue];
                        int sid = [sensor sensorId];
                        int avg = [stage1 processValue:raw fromSensor:sid];
                        int clamped = [stage2 processValue:avg fromSensor:sid];

                        int err = [pub publishSensorId:sid value:clamped timestamp:pass];
                        OZString *sname = [sensor name];
                        OZLog("    %s: raw=%d out=%d pub=%d\n",
                              [sname cStr], raw, clamped, err);
                }
                pass = pass + 1;
        }

        /* Block callback */
        [pub publishSensorId:1 value:99 timestamp:999 completion:^(int status) {
                _blockStatus = status;
                OZLog("  block callback: %d\n", status);
        }];

        OZLog("  publishes: %d\n", [pub publishCount]);
        OZLog("  last value: %d\n", [pub lastPublishedValue]);

        /* Step 14: cross-file header dependencies */
        PXSensorRegistry *registry = [[PXSensorRegistry alloc] initWithSensors:sensorArray];
        PXSystemStatus *status = [[PXSystemStatus alloc] initWithManager:mgr
                                                                registry:registry
                                                               publisher:pub
                                                                  logger:log];
        [status printStatus];

        /* Step 15: deep inheritance (4 levels) */
        OZLog("  === Deep inheritance test ===\n");
        PXBarometer *baro = [[PXBarometer alloc] initWithId:99];

        /* Level 4: PXBarometer method */
        int alt1 = [baro altitude];
        OZLog("  altitude 1: %d m\n", alt1);

        /* Level 3: PXPressureSensor method (cast to parent) */
        PXPressureSensor *psensor = (PXPressureSensor *)baro;
        int pressure = [psensor pressureReading];
        OZLog("  pressure: %d\n", pressure);

        /* Level 2: PXAnalogSensor methods (cast to parent) */
        PXAnalogSensor *analog = (PXAnalogSensor *)baro;
        int raw = [analog readRaw];
        int cal = [analog calibratedValue];
        OZLog("  raw: %d  calibrated: %d\n", raw, cal);

        /* Level 1: PXSensorBase methods (cast to grandparent) */
        PXSensorBase *base = (PXSensorBase *)baro;
        OZLog("  sensorId: %d\n", [base sensorId]);
        OZLog("  sampleCount: %d\n", [base sampleCount]);

        /* Overridden method at each level */
        OZString *tname = [baro typeName];
        OZLog("  typeName: %s\n", [tname cStr]);

        /* Second altitude reading — verify state accumulates */
        int alt2 = [baro altitude];
        OZLog("  altitude 2: %d m (should differ from alt1)\n", alt2);

        [mgr stop];
        [log info:@"done"];

        return 0;
}
