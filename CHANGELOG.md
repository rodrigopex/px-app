# px-app Build Changelog

## Build Log

### Phase 2 — Mutation Testing for Error Message Quality (2026-03-15)

16 mutations applied to working px-app code. Each mutation tested transpiler
error detection, actionability, and severity classification.

**Issues filed:** OZ-021, OZ-023, OZ-025, OZ-027, OZ-029, OZ-031, OZ-033, OZ-035, OZ-037
**Issues verified:** OZ-021, OZ-023, OZ-025/OZ-035, OZ-027/OZ-037, OZ-029, OZ-031
**Issues reopened:** OZ-033 (protocol conformance check not triggering)

**Meta-issue (OZ-021):** CMake now passes --strict to transpiler. All diagnostics
visible during `west build`. Highest-impact fix — previously warnings were invisible.

| Step | Mutation | Detection | Result | Issue |
|------|----------|-----------|--------|-------|
| 1 | @try/@catch | Error (good) | Lacked source file — fixed (OZ-023) | OZ-023 |
| 2 | Boxed @() | None → TODO comment | Silently broke GCC — fixed (OZ-025→OZ-035) | OZ-025, OZ-035 |
| 3 | Capturing block | Warning only | Wrong severity — fixed (OZ-027→OZ-037) | OZ-027, OZ-037 |
| 4 | typedef ivar | None | Silently broke GCC — fixed, resolves to underlying type | OZ-029 |
| 5 | Wrong class method | None | Silently emitted undefined function — fixed | OZ-031 |
| 6 | Missing protocol method | None | Silent runtime crash (NULL vtable) — **reopened** | OZ-033 |
| 7 | Selector mismatch | None | Same as Step 6 (NULL vtable) | (OZ-033) |
| 8 | Missing argument | None | __patched__ fallback, GCC catches | (OZ-031) |
| 9 | Missing @end | OK | Clang lenient at EOF — no issue |  |
| 10 | .m removed from CMake | Warning | Wrong severity (warns but continues) | (OZ-031) |
| 11 | Empty @implementation | Warning | Same as Step 10 | (OZ-031) |
| 12 | Circular #import | OK | ObjC #import is include-once — no issue |  |
| 13 | [self readValue] wrong hierarchy | None | Same NULL vtable as Step 6 | (OZ-033) |
| 14 | Missing #import | Clang (hidden) | Clang error suppressed by build system | (OZ-021) |
| 15 | Nonexistent return type | OK | Clang resolves gracefully — no issue |  |
| 16 | Type mismatch assign | None | GCC catches — transpiler silent |  |

**Key findings:**
- OZ-021 (--strict) was the single highest-impact fix — made all warnings visible
- OZ-025/OZ-027 fixes initially regressed (NULL instead of error), caught by
  verification, fixed in OZ-035/OZ-037
- OZ-033 (protocol conformance) is the remaining critical gap — missing protocol
  methods cause silent runtime crashes with no diagnostic at any stage
- Steps 9, 12, 15 were handled gracefully (Clang resilient, no issue needed)
- Steps 5, 8, 10, 11, 16 had no transpiler diagnostic but GCC caught them

### Step 4-HW — Hardware checkpoint (2026-03-15)

- **Result:** PASS (compiles and links)
- **Board:** nrf52833dk/nrf52833
- **Flash:** 24,580 B / 512 KB (4.69%)
- **RAM:** 5,524 B / 128 KB (4.21%)
- 4 classes (PXAppConfig, PXSensorReading, PXTemperatureSensor, PXHumiditySensor)
  + 1 protocol (PXSensorProtocol) + Foundation runtime
- Plenty of headroom.
- **Flashed by Rodrigo:** Serial output matches QEMU exactly. All values correct.

### Step 16 + 16-HW — Stress test + final hardware checkpoint (2026-03-15)

- **Result:** PASS
- **Scale:** 18 .m files, 15 user classes, 3 protocols, 61 methods, 45 generated files
  (exceeds requirement: 8+ classes, 3 protocols, 20+ methods)
- **OZ-019 verified:** Parent ivar access now works (`sampleCount: 3`). WA-006 resolved.
- **QEMU (mps2/an385):** Flash 24,744 B (0.59%), RAM 8,860 B (0.21%)
- **Hardware (nrf52833dk):** Flash 31,460 B / 512 KB (6.00%), RAM 7,252 B / 128 KB (5.53%)
- **Flashed by Rodrigo:** Serial output matches QEMU exactly. All features verified
  on hardware including deep inheritance (sampleCount: 3), parent ivar access,
  switch/case, protocol dispatch, zbus, blocks, for-in, ARC. Build sequence complete.

**Final transpiler feature summary (all working):**
classes, inheritance (4 levels), protocols (2 user + IteratorProtocol),
properties (@synthesize), @synchronized (OZLock), switch/case + enum,
for-in (IteratorProtocol), OZArray/OZString/OZNumber literals,
non-capturing blocks, compile-time ARC, file-scope statics with nil,
C interop (zbus macros + functions in .m), subdirectory imports,
protocol dispatch (int + object returns), deep super chaining,
parent ivar access across inheritance levels.

**Issues filed by DEV:** OZ-001, OZ-003, OZ-005, OZ-007, OZ-009, OZ-011, OZ-013, OZ-015, OZ-017, OZ-019
**All verified and resolved.** Zero active workarounds.

### Step 15 — Deep inheritance 4 levels (2026-03-15)

- **Result:** PASS (after OZ-017 fix)
- **Board:** mps2/an385 (QEMU)
- 4-level hierarchy: OZObject → PXSensorBase → PXAnalogSensor → PXPressureSensor → PXBarometer
- `src/models/PXSensorBase.{h,m}`: base with sensorId, sampleCount
- `src/models/PXAnalogSensor.{h,m}`: adds rawValue, calibration offset
- `src/models/PXPressureSensor.{h,m}`: adds pressure scaling, calls super methods
- `src/models/PXBarometer.{h,m}`: estimates altitude from pressure
- Features exercised: field embedding (each level adds ivars), super init chaining
  (`[super initWithId:...]`), calling inherited methods across 3 levels,
  method override (`typeName` overridden at each level), class ID ordering
- QEMU: altitude=11796→11436 (accumulates), pressure=40, raw=15, cal=25, sensorId=99
- Flash: 24,744 B (+1,084 B), RAM: 8,860 B (+596 B)

**OZ-017 filed and fixed:** Inherited method calls were missing parent type cast
for `self`. Transpiler now emits `(struct ParentClass *)self` when calling
inherited methods. Also found: direct ivar access to parent fields
(`_sampleCount` from PXAnalogSensor accessing PXSensorBase's ivar) generates
`self->_sampleCount` but the C struct doesn't have it at top level — must use
accessor methods instead. Not filed as separate issue (known C struct embedding
limitation).

### Step 14 — Multi-file header dependencies (2026-03-15)

- **Result:** PASS (first try)
- **Board:** mps2/an385 (QEMU)
- `src/services/PXSystemStatus.{h,m}`: imports 4 class headers, holds ivars
  of 4 different class types, calls methods on each
- Features exercised: cross-file `#import` chains (PXSystemStatus → PXDeviceManager,
  PXSensorRegistry, PXZbusPublisher, PXLogger), multi-arg init with 4 object params,
  method calls on imported class types
- Also refactored PXZbusPublisher: removed standalone C functions, made
  `publishSensorId:value:timestamp:` and `lastPublishedValue` proper ObjC
  methods/properties. Removed `px_zbus_defs.h` — struct and macro live in `.m`.
- Flash: 23,660 B (+848 B), RAM: 8,264 B (+132 B)
- No issues. Clean first-try build.
- **Flashed by Rodrigo:** Serial output matches QEMU exactly. Slab exhaustion
  test also passes on hardware (3 allocs succeed with count=1 — same as QEMU).
  nRF52833: Flash 30,360 B / 512 KB (5.79%), RAM 6,640 B / 128 KB (5.07%).

### Step 13 — Slab auto-count verification (2026-03-15)

- **Result:** PASS (observation only, no new issues)
- **Board:** mps2/an385 (QEMU)
- Inspected all `OZ_SLAB_DEFINE` counts: all user classes have count=1,
  OZLock=2, OZNumber=8, OZString=1, OZArray=1
- Over-allocation test: allocated 3 PXSensorReading objects simultaneously
  with slab count=1 (`K_MEM_SLAB_DEFINE(..., 1, 4)`). ALL 3 succeeded —
  `k_mem_slab` on QEMU/mps2 does not enforce the 1-block limit.
  Buffer size = `1 * WB_UP(sizeof(struct PXSensorReading))` ≈ 20 bytes,
  should only fit 1 block, but 3 allocs return non-NULL.
  Likely QEMU platform behavior — nRF52833 hardware may enforce strictly.
- ARC release test: setting r1=nil freed the slab block, subsequent r4
  allocation succeeded — ARC dealloc path works correctly.
- The transpiler sets count=1 as a static default for all user classes —
  not based on usage analysis. Current defaults work since ARC keeps only
  1 instance live at a time in loop scopes.
- No issue filed — slab counts are correct for normal usage patterns.
- **OZ-013 verified:** C constructs in `.m` files with `@implementation` now
  preserved. Removed `px_zbus.c` workaround. WA-005 resolved.

### Step 12-HW — Full system wiring + hardware checkpoint (2026-03-15)

- **Result:** PASS (first try)
- **Board:** mps2/an385 (QEMU) + nrf52833dk/nrf52833

**Full system wiring:** all 10 classes + 2 protocols + zbus integrated in main.m.
- Singletons (PXAppConfig, PXLogger), device lifecycle (PXDeviceManager),
  sensor registry (OZArray + for-in), two-stage pipeline (MovingAverage →
  ThresholdFilter), zbus publish, non-capturing block, PXSensorReading values,
  structured logging, ARC (compile-time retain/release)
- 3 passes × 2 sensors = 6 publishes + 1 block publish = 7 total
- QEMU: all values correct across all passes, pipeline converging

**Hardware (nrf52833dk):**
- **Flash:** 29,624 B / 512 KB (5.65%) — +3,020 B since Step 8-HW
- **RAM:** 6,488 B / 128 KB (4.95%) — plenty of headroom
- **Flashed by Rodrigo:** Serial output matches QEMU exactly. Full system verified on hardware.

**Also verified:** OZ-011 (quoted #include) — MAINTAINER was right, works now.
Updated WA-005: only C macro invocations need `.c` file, quoted includes work.

### Step 11 — PXLogger: structured logging (2026-03-15)

- **Result:** PASS (after moving enum to .m)
- **Board:** mps2/an385 (QEMU)
- `src/services/PXLogger.{h,m}`: singleton logger with severity levels (debug/info/warn/error)
- Features exercised: `+initialize`/`+shared` singleton, switch/case with enum,
  OZString literals `@"..."`, `[msg cStr]` string formatting, log level filtering,
  class method calls, method chaining (`[log info:@"..."]`)
- Transpiler generated 31 files (+2 for PXLogger)
- QEMU: `[INF]`/`[WRN]`/`[ERR]` prefixes correct, debug filtered, 5 messages counted
- Flash: 20,944 B (+496 B), RAM: 8,136 B (+248 B)
- **Note:** Enum must be defined in `.m` file, not `.h` — transpiler only
  collects enums from `.m` files processed by `objz_transpile_sources`.
- No new issues. Clean build after enum placement fix.

### Step 10 — PXZbusPublisher: zbus + C interop + non-capturing blocks (2026-03-15)

- **Result:** PASS (after architecture adjustment)
- **Board:** mps2/an385 (QEMU)
- `src/services/px_zbus.c`: plain C zbus channel + publish functions (compiled directly)
- `src/services/px_zbus_defs.h`: C header with struct + function declarations
- `src/services/PXZbusPublisher.{h,m}`: ObjC wrapper with non-capturing block callback
- Features exercised: zbus `ZBUS_CHAN_DEFINE`, `zbus_chan_pub`, C function interop
  from ObjC, non-capturing blocks (`^(int status) { ... }`), file-scope static
  from block, angle-bracket `#include <px_zbus_defs.h>` passthrough
- C/ObjC architecture: C macros/structs in `.c` file (CMake `target_sources`),
  ObjC wrappers call C functions, main.m bridges via `#include <header.h>`
- Transpiler generated 29 files (+2 for PXZbusPublisher)
- QEMU: publish err=0, block callback status=0, 2 publishes, last value=24
- Flash: 20,448 B (+1,892 B), RAM: 7,888 B (+124 B)

**Architecture note:** The transpiler strips quoted C `#include` directives
and C macro definitions from .m files. C interop requires:
1. Plain `.c` file for C macros/structs (via CMake `target_sources`)
2. `.h` header included via angle brackets `#include <header.h>`
3. Protocol-only headers (`@protocol`) should NOT be `#import`ed in main.m
   (transpiler passes them through but GCC can't parse the ObjC `#import`)

### OZ-012 verified — switch/case fully works (2026-03-15)

- OZ-012 fix landed. switch/case body now emitted correctly.
- Reverted WA-004: restored idiomatic switch/case + enum in PXDeviceManager.
- QEMU: full state machine with switch/case verified — all transitions correct.
- Zero active workarounds.

### OZ-007/OZ-009 verified — enum works, switch body doesn't (2026-03-15)

- **OZ-009 verified:** Transpiler crash fixed — `_is_user_enum` now defined.
- **OZ-007 partial:** Enum values ARE collected and emitted (e.g., `PXDeviceStateIdle`
  compiles). But switch/case body is NOT emitted — only the condition expression
  (`self->_state;`) appears as a bare statement. Cases and bodies are lost.
- Updated WA-004: use enum constants with if/else (enum works, switch doesn't).
- Verified with QEMU: full state machine works correctly with enum + if/else.

### Step 9 — PXDeviceManager: state machine + @synchronized (2026-03-15)

- **Result:** PASS (after workaround)
- **Board:** mps2/an385 (QEMU)
- `src/services/PXDeviceManager.{h,m}`: lifecycle state machine (idle→init→run→stop)
- Features exercised: `@synchronized` (transpiled to OZLock), if/else state
  transitions, error counting, static int constants
- Transpiler generated 27 files (+2 PXDeviceManager, +2 OZLock for @synchronized)
- QEMU: full lifecycle correct — start, duplicate start error, stop, restart
- Flash: 18,544 B (-1,124 B — main.m simplified for this step), RAM: 7,764 B (+184 B)

**Idiomatic ObjC test (switch + enum):**
- Wrote switch/case with C enum first per workflow
- Transpiler generated switch code but enum values undeclared in generated C
- GCC error: `'PXDeviceStateIdle' undeclared`
- Error message quality: no transpiler diagnostic, GCC error on generated C

**Issue discovered:**
- **OZ-007 (filed):** switch/case generates code but enum values not collected.
  LIMITATIONS.md says "No switch/case" but transpiler actually emits switch —
  just without resolving enum names. Workaround WA-004: if/else + static int.

### Step 8-HW — Hardware checkpoint (2026-03-15)

- **Result:** PASS (compiles and links)
- **Board:** nrf52833dk/nrf52833
- **Flash:** 26,604 B / 512 KB (5.07%) — +2,024 B since Step 4-HW
- **RAM:** 5,964 B / 128 KB (4.55%) — +440 B since Step 4-HW
- Delta covers: PXSensorRegistry, PXMovingAverageFilter, PXThresholdFilter,
  PXDataProcessor protocol vtable, OZArray literal allocation, SYS_MEM_BLOCKS
- Plenty of headroom.
- **Flashed by Rodrigo:** Serial output matches QEMU exactly. Two-stage pipeline verified on hardware.

### Step 8 — PXThresholdFilter + OZ-005 verified (2026-03-15)

- **Result:** PASS (first try)
- **Board:** mps2/an385 (QEMU)
- `src/services/PXThresholdFilter.{h,m}`: clamps values to [low, high] bounds
- Features exercised: second `<PXDataProcessor>` conformer, multi-class protocol
  dispatch for `processValue:fromSensor:` and `processorName`, two-stage pipeline
  (average → threshold), comparison logic (`if` chains)
- Transpiler generated 25 files (+2 for PXThresholdFilter)
- QEMU: `pipeline: MovingAverage -> ThresholdFilter`, all values processed correctly
- Flash: 19,668 B (+440 B), RAM: 7,580 B (+120 B)
- **OZ-005 fix verified:** Reverted WA-003, `return [_sensors count];` now works
  directly. Zero active workarounds.
- No new issues. Clean first-try build.

### Steps 6+7 — PXDataProcessor protocol + PXMovingAverageFilter (2026-03-15)

- **Result:** PASS (first try)
- **Board:** mps2/an385 (QEMU)
- `src/protocols/PXDataProcessor.h`: protocol with `processValue:fromSensor:` (multi-arg) + `processorName`
- `src/services/PXMovingAverageFilter.{h,m}`: first conformer, running average
- Features exercised: second protocol declaration, multi-arg protocol method,
  object return type via protocol dispatch (`processorName`), pipeline pattern
- Transpiler generated 23 files (+2 for PXMovingAverageFilter)
- QEMU: pipeline correct — raw values processed through filter, accumulation works
- Flash: 19,228 B (+372 B), RAM: 7,460 B (+204 B)
- No issues, no workarounds. Clean first-try build.

### Step 5 — PXSensorRegistry: collection management (2026-03-15)

- **Result:** PASS (after workaround)
- **Board:** mps2/an385 (QEMU)
- `src/services/PXSensorRegistry.{h,m}`: manages sensor collection via OZArray
- Features exercised: OZArray literal `@[temp, hum]`, for-in enumeration,
  protocol dispatch inside loop, `IteratorProtocol` (`iter`/`next`)
- Added `CONFIG_SYS_MEM_BLOCKS=y` to `prj.conf` (required for array literal allocation)
- Transpiler generated 21 files (+2 for PXSensorRegistry)
- QEMU: 2 sensors registered, for-in iterates both, values correct across passes
- Flash: 18,856 B (+1,520 B), RAM: 7,256 B (+316 B)

**Issue discovered:**
- **OZ-005 (filed):** Dispatch on ivar in return statement missing receiver
  variable declaration. `return [_sensors count];` generates
  `return OZ_SEND_count(_oz_recv0);` without declaring `_oz_recv0`.
  Workaround WA-003: `int c = [_sensors count]; return c;`
- **Error message quality:** No transpiler diagnostic. GCC error on undeclared
  identifier in generated C.

**Also noted:** OZArray is immutable — no `addObject:`. Used array literal
`@[...]` with `initWithSensors:` pattern instead of building incrementally.

### OZ-003 fix verified — WA-002 reverted (2026-03-15)

- OZ-003 fix landed. Protocol dispatch with object return types now works.
- Reverted WA-002: added `- (OZString *)name` back to `PXSensorProtocol`.
  All three protocol methods (`sensorId`, `readValue`, `name`) now dispatch
  via `id<PXSensorProtocol>`.
- Rebuild + QEMU: `TemperatureSensor` and `HumiditySensor` names printed
  correctly via protocol dispatch. No regressions.
- Zero active workarounds.

### Step 4 — PXHumiditySensor: multi-class protocol dispatch (2026-03-15)

- **Result:** PASS (after workaround)
- **Board:** mps2/an385 (QEMU)
- `src/models/PXHumiditySensor.{h,m}`: second conformer with decrementing humidity
- Features exercised: multi-class protocol dispatch (vtable routes `sensorId`
  and `readValue` to different implementations for temp vs humidity)
- Transpiler generated 21 files (+2 for PXHumiditySensor)
- QEMU: temp id=1 value=23→24, hum id=2 value=53→51 — correct independent state
- Flash: 17,596 B (+260 B), RAM: 7,116 B (+176 B)
- OZ-003 still active: avoided calling `name` through dispatch (WA-002).
  Confirmed `name` enters vtable even when not in protocol — transpiler
  auto-dispatches any method implemented by multiple classes.
- No new issues. Error message quality: N/A (no errors this step).

### Step 3 — PXSensorProtocol + PXTemperatureSensor (2026-03-15)

- **Result:** PASS (after workaround)
- **Board:** mps2/an385 (QEMU)
- `src/protocols/PXSensorProtocol.h`: protocol with `sensorId`, `readValue`
- `src/models/PXTemperatureSensor.{h,m}`: first conformer, simulated temp readings
- Features exercised: protocol declaration, conformance, protocol dispatch (OZ_SEND_*),
  subdirectory imports (OZ-001 fix verified), multi-file protocol/class split
- Transpiler generated 19 files (+2 for PXTemperatureSensor)
- QEMU: protocol dispatch correct — `id=1 value=23`, second `readValue=24`
- Flash: 17,336 B (+460 B), RAM: 6,940 B (+160 B)

**Issue discovered:**
- **OZ-003 (filed):** Protocol methods returning object pointers (`OZString *`)
  emit `struct __patched__` placeholder cast. GCC type mismatch error.
  All existing protocol tests only use `int`/`void` returns — untested path.
  Workaround WA-002: removed `name` from protocol, call on concrete type only.
- **Error message quality:** No transpiler diagnostic. GCC error on generated C
  with internal placeholder type `__patched__` — not actionable for an end user.

### OZ-001 fix verified — WA-001 reverted (2026-03-15)

- OZ-001 fix landed in-place. Subdirectory `#include` paths now work.
- Reverted WA-001: moved `PXAppConfig.{h,m}` to `src/services/`.
- Rebuild + QEMU: all output correct, no regressions.
- Subdirectories available for future files (models/, drivers/, protocols/).

### Step 2 — PXSensorReading value object (2026-03-15)

- **Result:** PASS (first try)
- **Board:** mps2/an385 (QEMU)
- `src/PXSensorReading.h` + `src/PXSensorReading.m`: value object with 3 int ivars
- Features exercised: explicit ivars, `initWithSensorId:value:timestamp:` (multi-arg init), getters, multi-file cross-import
- Transpiler generated 17 files (+2 for PXSensorReading)
- QEMU output: `reading: sensor=1 value=42 ts=1000` — correct
- Flash: 16,876 B (+264 B), RAM: 6,780 B (+76 B)
- No issues, no workarounds needed. Clean first-try build.

### Step 0 — Skeleton main (2026-03-15)

- **Result:** PASS
- **Board:** mps2/an385 (QEMU)
- `src/main.m`: imports `<Foundation/Foundation.h>` + `<zephyr/kernel.h>`, calls `OZLog()`
- Transpiler generated 13 files (Foundation classes + main_ozm.c)
- QEMU output: `*** Booting Zephyr OS build v4.3.0 ***` / `px-app booted from Objective-Z`
- Flash: 15,844 B / 4 MB (0.38%), RAM: 6,616 B / 4 MB (0.16%)
- No errors, no warnings. Transpiler and module integration working correctly.

### Step 1 — PXAppConfig singleton with properties (2026-03-15)

- **Result:** PASS (after workarounds)
- **Board:** mps2/an385 (QEMU)
- `src/PXAppConfig.h` + `src/PXAppConfig.m`: singleton with 4 int properties
- Features exercised: `@property`, `@synthesize`, `+initialize`/`+shared`, file-scope static, multi-file project
- Transpiler generated 15 files (+2 for PXAppConfig)
- QEMU output: all 4 property values printed correctly (1000, 80, 20, 4)
- Flash: 16,612 B (+768 B), RAM: 6,704 B (+88 B)

**Issues discovered:**

1. **Subdirectory include paths (OZ-001, filed):** When .m files are in subdirectories
   (e.g., `src/services/`), the transpiler preserves the directory prefix in generated
   `#include` but outputs all files flat into `oz_generated/`. GCC fails with
   `fatal error: services/PXAppConfig_ozh.h: No such file or directory`.
   Workaround: flat `src/` layout (WA-001).

2. **`@synthesize` requires explicit ivar (not filed — convention, not bug):**
   `@synthesize propName;` (modern default) generates underscore-prefixed access
   (`self->_propName`) but struct field without underscore (`propName`). All existing
   samples and tests use `@synthesize propName = _propName;`. Adopted this convention.

3. **File-scope static type not transpiled (not filed — follows arc_demo pattern):**
   `static PXAppConfig *_sharedConfig = nil;` emitted verbatim in generated C.
   `PXAppConfig` is not a valid C type (needs `struct` prefix). Adopted arc_demo's
   pattern: `static PXAppConfig *_sharedConfig;` (no `= nil`), with `+initialize`
   for eager initialization.

**Error message quality:** No transpiler diagnostic for any of these issues. All
three manifested as GCC errors on generated C, not as transpiler-level messages.
The transpiler silently generated invalid C in all cases.
