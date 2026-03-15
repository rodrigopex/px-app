# Phase 2: Mutation Testing for Transpiler Error Message Quality

## Context

Phase 1 built a 15-class sensor monitoring app (px-app) across 17 steps, filing 10 transpiler issues. A recurring pattern: the transpiler **silently generated invalid C** with no diagnostic — the developer only discovered problems when GCC failed on the generated output with cryptic errors referencing transpiler internals (`struct __patched__`, `_oz_recv0`, missing includes). The transpiler has a diagnostic system (`module.diagnostics` for warnings, `module.errors` for fatal errors, `--verbose`/`--strict` flags), but the CMake integration does NOT pass `--verbose` or `--strict`, making warnings invisible during normal builds.

**Goal:** Systematically inject 16 mutations into the working px-app code, evaluate the transpiler's error output, and file issues when diagnostics are missing, unclear, or misclassified. The outcome is a transpiler that gives actionable, source-located error messages for every construct it cannot handle.

## Workflow per step

1. DEV applies ONE mutation to the working code
2. DEV runs `west build -b mps2/an385 -p` and captures full output
3. DEV evaluates against 3 criteria:
   - **Detection:** Does the transpiler detect the issue? (error / diagnostic / nothing / Clang catches it)
   - **Actionability:** Does the message name the source file, line, construct, and suggest a fix?
   - **Severity:** Is it correctly classified? (errors that produce invalid C should be `module.errors`, not silent `module.diagnostics`)
4. If output is not good enough → file `issues/OZ-NNN.md` (DEV odd IDs starting OZ-021)
5. DEV reverts the mutation and confirms the build passes again
6. This chat is the DEV agent — same role and workflow as Phase 1

## Critical finding

The CMake integration (`oz_transpile.cmake`) does NOT pass `--verbose` or `--strict` to the transpiler. Diagnostics appended to `module.diagnostics` (warnings) are invisible during `west build`. Only `module.errors` are shown. **Any construct that produces invalid C must be classified as an error, not a warning.**

## 16 Mutation Steps

### Group A: Documented Unsupported Constructs (Steps 1-4)

| Step | Mutation | File | What to check |
|------|----------|------|---------------|
| 1 | Add `@try { ... } @catch (id e) { ... }` around switch in `start` method | `PXDeviceManager.m` | Error exists in collect.py but may lack source file/line info |
| 2 | Replace `return _sum / _count;` with `OZNumber *r = @(_sum / _count); return [r intValue];` | `PXMovingAverageFilter.m` | Emits `/* TODO: ObjCBoxedExpr */` comment silently — no error |
| 3 | Capture local variable in block: add `int x = 42;` then use `x` inside the completion block | `main.m` | Diagnostic exists but classified as warning (invisible without --verbose) |
| 4 | Add `typedef int PXLogSeverity;` and use as ivar/param type | `PXLogger.h` + `.m` | Clang may resolve typedef in AST — test if transpiler silently drops it |

### Group B: Type and Dispatch Edge Cases (Steps 5-8)

| Step | Mutation | File | What to check |
|------|----------|------|---------------|
| 5 | Call wrong class's method: `[mgr info:@"test"]` | `main.m` | Transpiler silently emits undefined function |
| 6 | Remove `readValue` method from PXTemperatureSensor | `PXTemperatureSensor.m` | Missing protocol method — vtable entry missing |
| 7 | Change selector to `processValue:fromSensor:extra:` in PXThresholdFilter | `.h` + `.m` | Selector mismatch vs protocol |
| 8 | Call `[stage1 processValue:raw]` (missing second arg) | `main.m` | Clang should catch |

### Group C: Structural / Syntax Mutations (Steps 9-12)

| Step | Mutation | File | What to check |
|------|----------|------|---------------|
| 9 | Delete final `@end` | `PXSensorReading.m` | Clang should catch |
| 10 | Remove `.m` from `objz_transpile_sources()` | `CMakeLists.txt` | Silent linker fail |
| 11 | Delete all method bodies in `@implementation PXSensorReading` | `PXSensorReading.m` | Silent linker fail |
| 12 | Add circular `#import` between PXTemperatureSensor.h and PXHumiditySensor.h | Both `.h` files | Should be OK (include-once) |

### Group D: Subtle Edge Cases (Steps 13-16)

| Step | Mutation | File | What to check |
|------|----------|------|---------------|
| 13 | Call `[self readValue]` inside PXBarometer (protocol method not in hierarchy) | `PXBarometer.m` | Runtime fail, no diagnostic |
| 14 | Remove `#import "services/PXLogger.h"` from PXSystemStatus.h | `PXSystemStatus.h` | Clang should catch |
| 15 | Change `typeName` return type to `PXFoo *` (nonexistent class) | `PXSensorBase.h` + overrides | Clang should catch |
| 16 | Assign OZString* to int ivar: `_errorCount = @"error";` | `PXDeviceManager.m` | Clang may warn but pass |

## Meta-issue: --verbose not passed by CMake

Filed as OZ-021.
