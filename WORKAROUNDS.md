# Active Workarounds

(none)

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
