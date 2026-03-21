# Active Workarounds

## WA-007: Duplicate enum in each .m file (OZ-068)

- **Issue:** OZ-068 — enum defined in user header not emitted in generated C
- **Workaround:** Define `enum PXSensorType`, `enum PXDeviceState`, and
  `enum PXLogLevel` in each `.m` file that uses the constants. The transpiler
  only emits enum definitions found in the `.m` translation unit, not from
  included headers.
- **Files affected:**
  - `src/models/PXSensorBase.m` — PXSensorType
  - `src/models/PXAnalogSensor.m` — PXSensorType
  - `src/models/PXPressureSensor.m` — PXSensorType
  - `src/models/PXBarometer.m` — PXSensorType
  - `src/models/PXTemperatureSensor.m` — PXSensorType
  - `src/models/PXHumiditySensor.m` — PXSensorType
  - `src/main.m` — PXSensorType, PXDeviceState, PXLogLevel
- **Revert:** Once OZ-068 is fixed, move enums to `.h` headers and remove
  duplicates from `.m` files.

# Resolved Workarounds

## WA-005: Separate .c file for C interop (OZ-013) — RESOLVED

- **Issue:** OZ-013 — C constructs stripped from `.m` files with `@implementation`
- **Fix verified:** 2026-03-15. Patched-source path now preserves C code before
  `@implementation` blocks. Includes, macros, C functions all survive.
- **Reverted:** Moved `ZBUS_CHAN_DEFINE`, C functions back into `PXZbusPublisher.m`.
  Removed `px_zbus.c` and `target_sources` from CMakeLists.txt.

## WA-004: if/else instead of switch/case (OZ-007/OZ-012) — RESOLVED

- **Issue:** OZ-007 (enum not collected), OZ-012 (switch body not emitted)
- **Fix verified:** 2026-03-15. Both enum collection and switch/case emission work.
- **Reverted:** Restored idiomatic switch/case + enum in PXDeviceManager.

## WA-003: Local var for ivar dispatch in return statements (OZ-005) — RESOLVED

- **Issue:** OZ-005 — dispatch on ivar in return statement missing receiver variable
- **Fix verified:** 2026-03-15. Receiver variable now emitted correctly.
- **Reverted:** `return [_sensors count];` works directly.

## WA-002: No object return types in protocol methods (OZ-003) — RESOLVED

- **Issue:** OZ-003 — protocol dispatch emitted `struct __patched__` cast
- **Fix verified:** 2026-03-15. Protocol dispatch now casts to declared return type.
- **Reverted:** Added `- (OZString *)name` back to `PXSensorProtocol`.

## WA-001: Flat source layout (OZ-001) — RESOLVED

- **Issue:** OZ-001 — subdirectory `#include` paths broken in generated output
- **Fix verified:** 2026-03-15. Transpiler now flattens subdirectory prefixes.
- **Reverted:** Moved `PXAppConfig.{h,m}` to `src/services/`.
