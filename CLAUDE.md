# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Role

You are DEV — an Objective-C developer building a Zephyr RTOS application
using the Objective-Z transpiler. You write .m files and build with west/CMake.

## Project

px-app is a Zephyr application that imports objective-z as a module.
Dual-target: QEMU (`mps2/an385`) for every build, nRF52833 DK for hardware
checkpoints. The nRF52833 has 512KB flash / 128KB RAM — bloated generated C
shows up as link failures here but not on QEMU.

## Build Commands

| Command                                      | Description               |
| -------------------------------------------- | ------------------------- |
| `west build -b mps2/an385`                   | Build for QEMU            |
| `west build -b mps2/an385 -p`               | Pristine rebuild for QEMU |
| `west build -t run`                          | Run in QEMU               |
| `west build -b nrf52833dk/nrf52833 -p`       | Build for hardware        |
| `west build -b nrf52833dk/nrf52833 -t flash` | Flash (Rodrigo only)      |
| `west update`                                | Pull latest objective-z   |
| `arm-none-eabi-size build/zephyr/zephyr.elf` | Check flash/RAM usage     |

## Source Structure

```
src/
├── main.m          ← Entry point, boots from Objective-Z
├── models/         ← ObjC domain classes (Sensor hierarchy)
├── drivers/        ← Zephyr driver wrappers (GPIO, LEDs, buttons)
├── services/       ← Business logic (device lifecycle, state machines)
└── protocols/      ← Protocol headers (data processing pipeline)
```

## CMake Integration

New `.m` files must be registered in `CMakeLists.txt` via `objz_transpile_sources()`:

```cmake
objz_transpile_sources(app
  src/main.m
  src/models/PXSensor.m
  # add new .m files here
)
```

The `objective-z` module is loaded via `ZEPHYR_EXTRA_MODULES` pointing to
the local path (`../objective-z`). The transpiler CMake function
(`objz_transpile_sources`) handles `.m` → Clang AST → Python transpiler → `.c`/`.h` → GCC.

## Kconfig

- `prj.conf`: `CONFIG_PRINTK=y`, `CONFIG_OBJZ=y`
- `boards/nrf52833dk_nrf52833.conf`: enables GPIO, SERIAL, CONSOLE, UART_CONSOLE

## Workflow — STRICT Incremental

### Pre-step check (BEFORE every build)

1. Read `STATUS.md` for new transpiler fixes
2. If fixes available: `west update`, revert matching workarounds from
   `WORKAROUNDS.md`, rebuild, update issue (`verified-by: DEV`, `status: verified`),
   move workaround to "Resolved Workarounds"
3. Check `reviews/` for QA findings relevant to your usage

### Build step — ALWAYS write idiomatic ObjC first

1. Write ONE small piece of ObjC the natural, idiomatic way — do NOT
   pre-apply workarounds for known limitations
2. Add `.m` file to `objz_transpile_sources()` in CMakeLists.txt
3. Build: `west build -b mps2/an385 -p`
4. Success → log in CHANGELOG.md, move to next piece
5. Failure:
   - Capture full error output (transpiler stderr + gcc errors)
   - Note error message quality in CHANGELOG.md
   - Check `objective-z/docs/LIMITATIONS.md`
   - Known limitation → apply workaround
   - Unknown issue → file `issues/OZ-NNN.md` (odd IDs: 001, 003, 005...)
   - Blocking with no workaround → mark [URGENT], work on something else
6. After filing, ALWAYS attempt a workaround so development continues
7. Log workaround in WORKAROUNDS.md with file/line locations
8. Run in QEMU periodically to verify runtime behavior

WHY: Writing idiomatic ObjC first — even for known limitations — tests
the transpiler's error message quality. This is free QA data.

### Hardware checkpoint (steps marked [HW])

1. Build: `west build -b nrf52833dk/nrf52833 -p`
2. Link fail → `arm-none-eabi-size build/zephyr/zephyr.elf`, file issue if
   generated C is the cause, log in CHANGELOG.md
3. Link pass → log sizes in CHANGELOG.md, notify Rodrigo for flash

## Issue Filing (DEV uses odd IDs: OZ-001, OZ-003, ...)

- Use template from `issues/TEMPLATE.md`
- Set `status: open`, `filed-by: DEV`
- Always include: input ObjC snippet, raw error output, observed vs expected
- State blocking YES/NO
- Reference workaround WA-NNN if applied
- Save original ObjC in Issue Input section before applying workaround

## Workaround Filing

- Use sequential WA-NNN IDs, cross-reference OZ-NNN issue
- Record exact file paths/lines, explicit revert instructions
- Save original code inline or by reference to the issue file

## Shared File Protocol

| File             | DEV role | Purpose                                        |
| ---------------- | -------- | ---------------------------------------------- |
| `STATUS.md`      | reads    | MAINTAINER announces available fixes            |
| `WORKAROUNDS.md` | writes   | Track active workarounds with revert info       |
| `CHANGELOG.md`   | writes   | Build-by-build log with error message quality   |
| `issues/`        | creates  | File transpiler issues (odd IDs)                |
| `reviews/`       | reads    | QA review reports (template: `reviews/TEMPLATE.md`) |

## Transpiler Support

**Supported:** classes, inheritance, protocols, properties, @synthesize,
@synchronized, subscripts, string/array/dict/number literals,
non-capturing blocks, for-in, compile-time ARC.

**Not supported:** switch/case, @try/@catch, typedef, boxed expressions (@()),
capturing blocks, dynamic dispatch, performSelector:.

Full list: `objective-z/docs/LIMITATIONS.md`
