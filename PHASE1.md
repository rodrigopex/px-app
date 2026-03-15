# Multi-Agent Transpiler Acceleration Plan

## Goal

Accelerate objective-z transpiler development by running three Claude Code agents in parallel against **separate repositories** that share state through filesystem conventions. **DEV** builds a real ObjC application incrementally, discovering transpiler gaps. **MAINTAINER** fixes those gaps. **QA** reviews every fix for code quality, usability, error messaging, and regressions — catching what MAINTAINER (focused on making tests pass) and DEV (focused on making the app build) both miss. A file-based protocol minimizes the human touchpoints needed to keep all three agents productive.

---

## Repository Layout

```
~/projects/
├── objective-z/              ← MAINTAINER's repo (transpiler module)
│   ├── tools/oz_transpile/   ← transpiler source
│   ├── include/oz_sdk/       ← SDK headers (OZObject, OZString, etc.)
│   ├── include/platform/     ← PAL headers
│   ├── src/                  ← Foundation .m stubs
│   ├── cmake/                ← oz_transpile.cmake, ObjcClang.cmake
│   ├── tests/                ← transpiler tests
│   └── zephyr/module.yml
│
├── objective-z-qa/           ← QA's read-only clone (git pull before each review)
│
└── px-app/                   ← DEV's repo (Zephyr application)
    ├── west.yml              ← imports objective-z as local module
    ├── CMakeLists.txt
    ├── prj.conf
    ├── boards/
    ├── src/
    │   ├── main.m
    │   ├── models/           ← ObjC domain classes
    │   ├── drivers/          ← Zephyr driver wrappers
    │   ├── services/         ← Business logic
    │   └── protocols/        ← Protocol headers
    ├── issues/               ← one file per issue (shared contract)
    │   ├── OZ-001.md         ← DEV uses odd IDs
    │   ├── OZ-002.md         ← QA uses even IDs
    │   └── ...
    ├── reviews/              ← QA writes review reports here
    │   ├── QR-001.md
    │   ├── QR-002.md
    │   └── ...
    ├── STATUS.md             ← MAINTAINER writes, DEV reads
    ├── WORKAROUNDS.md        ← DEV writes, MAINTAINER reads
    └── CHANGELOG.md          ← DEV's build-by-build log
```

### px-app west.yml

During local development, `west.yml` points to MAINTAINER's local clone so DEV can pull fixes without a GitHub round-trip. Switch to the remote URL for CI.

```yaml
# Local development — DEV pulls from MAINTAINER's working tree
manifest:
  remotes:
    - name: zephyrproject-rtos
      url-base: https://github.com/zephyrproject-rtos

  projects:
    - name: zephyr
      remote: zephyrproject-rtos
      revision: main
      import:
        name-allowlist:
          - cmsis
          - hal_nordic # Required for nrf52833dk

    - name: objective-z
      url: /Users/rodrigo/projects/objective-z
      revision: main
      path: modules/objective-z

  self:
    path: px-app
```

```yaml
# CI / remote — swap in when pushing to GitHub Actions
- name: objective-z
  url: https://github.com/rodrigopex/objective-z
  revision: main
  path: modules/objective-z
```

### px-app CMakeLists.txt (starter)

```cmake
cmake_minimum_required(VERSION 3.20.0)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(px_app)

target_include_directories(app PRIVATE src)

objz_transpile_sources(app
  src/main.m
  # DEV adds .m files here incrementally
)
```

### px-app prj.conf

```ini
CONFIG_PRINTK=y
CONFIG_OBJZ=y
```

### px-app boards/nrf52833dk_nrf52833.conf (board-specific overlay)

```ini
CONFIG_GPIO=y
CONFIG_SERIAL=y
CONFIG_CONSOLE=y
CONFIG_UART_CONSOLE=y
```

---

## Shared Files — The Agent Protocol

Four shared surfaces coordinate three agents. Each has clear ownership rules to prevent collision.

| File              | DEV     | MAINTAINER                | QA                          | Rodrigo           |
| ----------------- | ------- | ------------------------- | --------------------------- | ----------------- |
| `issues/OZ-*.md`  | creates | updates status/resolution | reads, files quality issues | answers questions |
| `reviews/QR-*.md` | reads   | reads, responds           | creates                     | reads             |
| `STATUS.md`       | reads   | writes                    | reads                       | reads             |
| `WORKAROUNDS.md`  | writes  | reads                     | reads                       | reads             |
| `CHANGELOG.md`    | writes  | —                         | reads                       | reads             |

### 1. `issues/` Directory — DEV and QA write, MAINTAINER reads

Each issue is an atomic file. Both DEV and QA can file issues, distinguished by `filed-by`.

**Issue lifecycle:** `status: open` → `status: in-progress` → `status: resolved` → `status: qa-passed` → `status: verified`

The new `qa-passed` state means QA has reviewed the fix. DEV verification and QA review happen in parallel — neither blocks the other. The issue reaches `verified` when DEV confirms the app builds, regardless of QA status. QA findings that need action become new issues or review findings.

**Template — `issues/OZ-NNN.md`:**

````markdown
# OZ-NNN: [URGENT] Short title

- **status:** open
- **filed-by:** DEV | QA
- **date:** 2026-03-15
- **blocking:** YES
- **assigned-to:** (empty until MAINTAINER picks it up)
- **resolved-by:** (empty until fixed)
- **resolved-date:** (empty until fixed)
- **qa-review:** (empty | QR-NNN reference | PASS | WAIVED)
- **verified-by:** (empty until DEV confirms)
- **commit:** (empty until fixed)

## Context

Trying to add state machine in `src/services/PXDeviceManager.m`.

## Input

```objc
switch ([self state]) {
    case SensorStateIdle: ...
}
```
````

## Observed

Build fails — transpiler emits `/* TODO: SwitchStmt */` comment. GCC then
fails on the incomplete generated C.

## Expected

Transpiled C equivalent using if/else chain or jump table.

## Workaround

Rewrote as if/else chain manually. See WORKAROUNDS.md entry WA-001.

## Discussion

- **MAINTAINER (2026-03-15):** Is this a collect.py gap or emit.py gap?
- **RODRIGO (2026-03-15):** collect.py — `SwitchStmt` is not walked at all.
  Add a handler in `_walk_stmt()` that decomposes into chained `IfStmt`.
- **MAINTAINER (2026-03-15):** Got it, implementing.

## Resolution

(filled by MAINTAINER when fixed)

````

**Key rules:**
- `[URGENT]` in title = DEV is blocked, MAINTAINER prioritizes
- `status` field is the machine-readable state — agents parse this
- **ID allocation: DEV uses odd IDs (OZ-001, OZ-003, ...), QA uses even IDs (OZ-002, OZ-004, ...)**. This prevents collision when both agents create issues simultaneously.
- QA-filed issues use `filed-by: QA` and typically aren't `[URGENT]` (they're quality, not blocking)
- Discussion is append-only, timestamped, with author labels
- `qa-review` field links to the QA review report or says `PASS`/`WAIVED`

### 2. `reviews/` Directory — QA writes, everyone reads

QA writes one review report per MAINTAINER fix. This is QA's primary output.

**Template — `reviews/QR-NNN.md`:**

```markdown
# QR-NNN: Review of OZ-001 fix (switch statement support)

- **issue:** OZ-001
- **commit:** abc1234
- **date:** 2026-03-15
- **verdict:** PASS | PASS_WITH_NOTES | FAIL | NEEDS_FOLLOWUP

## Checklist

- [ ] Generated C compiles cleanly (no warnings with -Wall -Wextra)
- [ ] Generated C is readable (meaningful variable names, comments for non-obvious transforms)
- [ ] Generated C is size-efficient (no dead code, no unnecessary dispatch entries — matters for nRF52833's 512KB flash)
- [ ] Transpiler stdout shows clear progress/status for this feature
- [ ] Transpiler stderr gives actionable error on malformed input for this feature
- [ ] LIMITATIONS.md updated (removed limitation or added new caveat)
- [ ] Edge cases tested (empty switch, single case, fall-through, default-only)
- [ ] No regressions in existing golden tests
- [ ] No regressions in existing behavior tests
- [ ] `--verbose` output includes useful diagnostic for this transform
- [ ] `--strict` mode rejects known-bad input with clear error message

## Generated C Quality

(Assessment of the generated output — is it debuggable? Does it match
what a human would write? Are there unnecessary casts, redundant variables,
or confusing naming?)

Example generated output for review:
```c
(paste relevant snippet of generated C and annotate)
````

## Error Messaging

(What happens when the transpiler encounters an error case related to
this feature? Test with deliberately malformed input.)

Tested: `switch` with no cases → transpiler reports: "..."
Tested: `switch` with fall-through → transpiler reports: "..."

## Regressions

(Did any previously passing tests break? List any golden-file diffs
that changed unexpectedly.)

## Findings

### Finding 1: [severity: low|medium|high] Short description

(Detail. If this needs a fix, QA files a new issue OZ-NNN.)

### Finding 2: ...

## Notes to MAINTAINER

(Optional: suggestions for improvement, patterns noticed across
multiple fixes, test coverage gaps to address.)

````

**Verdicts:**
- `PASS` — fix is clean, no findings
- `PASS_WITH_NOTES` — fix works but QA has suggestions for MAINTAINER (non-blocking)
- `NEEDS_FOLLOWUP` — QA found issues that need new OZ-NNN issues filed
- `FAIL` — fix has a serious quality or regression problem; QA files `[URGENT]` issue

**Key rules:**
- QA creates one `QR-NNN.md` per reviewed fix
- QA updates the original issue's `qa-review` field with the QR reference
- `NEEDS_FOLLOWUP` findings become new `issues/OZ-NNN.md` filed by QA
- `FAIL` is rare — only for regressions or broken error paths, not style preferences

### 3. `STATUS.md` — MAINTAINER writes, DEV and QA read

Eliminates the "Rodrigo tells DEV to pull" step. DEV and QA both check this file autonomously.

```markdown
# Transpiler Status

## Latest available fixes

| Issue | Title | Commit | Date | QA |
|-------|-------|--------|------|----|
| OZ-001 | Switch statement support | abc1234 | 2026-03-15 | QR-001: PASS |
| OZ-003 | Custom getter name | def5678 | 2026-03-16 | QR-002: PASS_WITH_NOTES |

## Pending (in progress)

| Issue | Title | ETA |
|-------|-------|-----|
| OZ-005 | Boxed expressions | ~2026-03-17 |

## Notes to DEV

- After pulling OZ-001 fix, remove if/else workaround in PXDeviceManager.m
  and restore original switch block.
- OZ-003 fix changes the generated getter function name format to
  `ClassName_customGetterName()` — no action needed from DEV, it's transparent.
````

**Key rules:**

- MAINTAINER appends to "Latest available fixes" after each commit
- MAINTAINER updates the QA column after QA review completes
- DEV reads this at the start of every build step
- QA reads this to discover which fixes need review

### 4. `WORKAROUNDS.md` — DEV writes, MAINTAINER and QA read

Tracks technical debt. Gives MAINTAINER context for fix design and QA context for review scope.

```markdown
# Active Workarounds

## WA-001: switch → if/else (blocked on OZ-001)

- **Issue:** OZ-001
- **Files affected:** src/services/PXDeviceManager.m
- **Lines:** 45-78
- **Applied:** 2026-03-15
- **Original code:** saved in issues/OZ-001.md under Input section
- **Revert when:** OZ-001 resolved, `west update` pulled
- **Revert instructions:** Replace if/else chain at lines 45-78 with original
  switch block. Rebuild and verify.
- **Status:** ACTIVE

## WA-002: file-scope static for singleton (known limitation)

- **Issue:** OZ-002
- **Files affected:** src/services/PXAppConfig.m
- **Lines:** 3-4, 12
- **Applied:** 2026-03-15
- **Original code:** method-local `static PXAppConfig *instance = nil;`
- **Revert when:** transpiler supports function-local static variables
- **Revert instructions:** Move static declaration back inside `+shared` method body.
- **Status:** ACTIVE (accepted limitation, low priority)

# Resolved Workarounds

## WA-003: manual nil guard for protocol dispatch (was OZ-004)

- **Reverted:** 2026-03-16 after OZ-004 fix
- **Status:** REVERTED
```

---

## Agent: DEV

### Identity

An experienced Objective-C and embedded systems developer building a non-trivial Zephyr application using Objective-Z. Thinks in ObjC idioms first, writes `.m` files, and relies on the transpiler to produce correct C.

### CLAUDE.md for DEV (px-app repo)

```markdown
# CLAUDE.md

## Role

You are DEV — an Objective-C developer building a Zephyr RTOS application
using the Objective-Z transpiler. You write .m files and build with west/CMake.

## Project

px-app is a Zephyr application that imports objective-z as a module.
Dual-target development:

- **QEMU (`mps2/an385`)** — every build step, fast iteration, agent-driven
- **Hardware (`nrf52833dk/nrf52833`)** — periodic checkpoints, Rodrigo flashes and reports

The nRF52833 has 512KB flash and 128KB RAM. If the transpiler generates
bloated C, it will show up as link failures or OOM here but not on QEMU.

## Build Commands

| Command                                      | Description               |
| -------------------------------------------- | ------------------------- |
| `west build -b mps2/an385`                   | Build for QEMU            |
| `west build -b mps2/an385 -p`                | Pristine rebuild for QEMU |
| `west build -t run`                          | Run in QEMU               |
| `west build -b nrf52833dk/nrf52833 -p`       | Build for hardware        |
| `west build -b nrf52833dk/nrf52833 -t flash` | Flash (Rodrigo only)      |

DEV builds for QEMU on every step. DEV also builds for nrf52833dk at
hardware checkpoints (steps marked [HW]) — but only to verify it compiles
and links. Rodrigo handles actual flashing and serial capture.

## Workflow — STRICT incremental

### Pre-step check (do this BEFORE every build step)

1. Read `STATUS.md` — check if new transpiler fixes are available
2. If fixes listed that aren't pulled yet:
   a. Run `west update` to pull latest objective-z module
   b. Check `WORKAROUNDS.md` for entries that reference the fixed issues
   c. Revert those workarounds (restore original ObjC code)
   d. Rebuild to verify the fix works
   e. Update the issue file: set `verified-by: DEV` and `status: verified`
   f. Update `WORKAROUNDS.md`: move entry to "Resolved Workarounds"
3. Check `reviews/` — read any QA reviews for fixes you've pulled
   (QA may have found edge cases relevant to your usage)
4. Continue to the next build step

### Build step — ALWAYS write idiomatic ObjC first

1. Write ONE small piece of ObjC — **the natural, idiomatic way** you
   would write it. Do NOT pre-apply workarounds for known limitations.
2. Add the .m file to CMakeLists.txt `objz_transpile_sources()`
3. Build (`west build -b mps2/an385 -p`)
4. If build succeeds: log in CHANGELOG.md, move to next piece
5. If build fails:
   a. **Capture the full error output** (transpiler stderr + gcc errors)
   b. Note the quality of the error message — is it actionable? Does it
   tell you what went wrong and what to do instead? Log this in CHANGELOG.md.
   c. THEN check docs/LIMITATIONS.md in the objective-z module
   d. If known limitation with documented workaround: apply workaround
   e. If unknown issue: file in issues/OZ-NNN.md (use odd IDs: 001, 003, 005...)
   f. If blocking with no workaround: mark [URGENT], work on something else
6. After filing, ALWAYS attempt a workaround so development continues
7. Log every workaround in WORKAROUNDS.md with file/line locations
8. In CHANGELOG.md, always note the error message quality
   (e.g., "transpiler gave clear message: 'SwitchStmt not supported at line 45'"
   or "transpiler crashed with no message" or "GCC error on generated C, no
   transpiler diagnostic")
9. Run in QEMU periodically to verify runtime behavior

WHY: Writing idiomatic ObjC first — even for known limitations — tests
what the transpiler's error message looks like. This is free QA data.
Jumping straight to workarounds skips that signal.

### Hardware checkpoint (steps marked [HW] in the build sequence)

1. Build for hardware: `west build -b nrf52833dk/nrf52833 -p`
2. If link fails (flash/RAM overflow):
   a. Run `arm-none-eabi-size build/zephyr/zephyr.elf` to check section sizes
   b. File issue if generated C is the cause (bloated dispatch tables,
   unnecessary copies, oversized slabs)
   c. Log flash/RAM usage in CHANGELOG.md for tracking
3. If link succeeds: log sizes in CHANGELOG.md, notify Rodrigo for flash
4. Rodrigo flashes the board and pastes serial output back into the chat
5. DEV verifies output matches QEMU behavior

## Issue Filing Rules

- **DEV uses odd IDs: OZ-001, OZ-003, OZ-005, ...** (QA uses even IDs)
- Check existing files in issues/ directory to find the next odd number
- Create a new file: issues/OZ-NNN.md using the template in issues/TEMPLATE.md
- Set status: open, filed-by: DEV
- Always include: input ObjC snippet, observed behavior, expected behavior
- **Always include the raw error output** from the transpiler/compiler
- Always state whether blocking (YES/NO)
- If you applied a workaround, describe it and reference the WA-NNN entry
- Be precise: error messages, generated C output path if relevant
- Save original ObjC code in the issue Input section before applying workaround

## Workaround Filing Rules

- Use next sequential WA-NNN ID
- Cross-reference the OZ-NNN issue
- Record exact file paths and line numbers affected
- Write explicit revert instructions (what to change back)
- Save the original code either inline or by reference to the issue file

## What You Build

A sensor monitoring system targeting both QEMU and the nRF52833 DK:

- Device driver wrappers (GPIO — nRF52833 DK has 4 LEDs and 4 buttons)
- Sensor model hierarchy (base Sensor, subclasses per type)
- Protocol-based data processing pipeline
- State machines for device lifecycle
- Zbus integration for inter-component messaging
- Configuration management (singleton, properties)
- Logging subsystem using OZLog

Build complexity incrementally. Start with the simplest class, prove it
transpiles and runs on QEMU, then layer on features. At hardware checkpoints
([HW] steps), also build for nrf52833dk and report flash/RAM usage.

## Transpiler Reference

The transpiler supports: classes, inheritance, protocols, properties,
@synthesize, @synchronized, subscripts, string/array/dict/number literals,
non-capturing blocks, for-in, compile-time ARC.

NOT supported: switch/case, @try/@catch, typedef, boxed expressions (@()),
capturing blocks, dynamic dispatch, performSelector:.

See objective-z/docs/LIMITATIONS.md for the full list.
```

### DEV Build Sequence (the application it builds)

The application is a **sensor monitoring system** for Cortex-M. This is deliberately complex enough to exercise most transpiler features:

| Step  | What DEV Adds                                        | Features Exercised                                                                                                 |
| ----- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| 0     | Skeleton `main.m` — printk + return 0                | Module import, `objz_transpile_sources()`, QEMU boot, proves toolchain works                                       |
| 0-HW  | Build step 0 for nrf52833dk                          | Proves hardware toolchain, baseline flash/RAM usage                                                                |
| 1     | `PXAppConfig` — singleton with properties            | `+shared` pattern, `@property`, file-scope static                                                                  |
| 2     | `PXSensorReading` — value object                     | ivars, init with args, getters                                                                                     |
| 3     | `<PXSensorProtocol>` + `PXTemperatureSensor`         | protocol declaration, conformance, protocol dispatch                                                               |
| 4     | `PXHumiditySensor` (2nd conformer)                   | multi-class protocol dispatch, vtable generation                                                                   |
| 4-HW  | Hardware checkpoint                                  | Flash/RAM delta after 4 classes + 1 protocol, Rodrigo flashes, verify serial                                       |
| 5     | `PXSensorRegistry` — collection management           | OZArray, OZDictionary, for-in enumeration                                                                          |
| 6     | `<PXDataProcessor>` pipeline                         | protocol chain, multiple args, return values                                                                       |
| 7     | `PXMovingAverageFilter : OZObject <PXDataProcessor>` | inheritance + protocol                                                                                             |
| 8     | `PXThresholdFilter : OZObject <PXDataProcessor>`     | another conformer, comparison logic                                                                                |
| 8-HW  | Hardware checkpoint                                  | Flash/RAM delta after data pipeline, check dispatch table size in .elf                                             |
| 9     | `PXDeviceManager` — lifecycle with states            | state machine (try switch first, let it fail, capture error, then workaround), @synchronized                       |
| 10    | `PXZbusChannel` + `PXZbusPublisher`                  | zbus integration, C interop, non-capturing blocks                                                                  |
| 11    | `PXLogger` — structured logging                      | OZLog, string formatting, class method calls                                                                       |
| 12    | `main.m` — full system wiring                        | alloc/init, protocol dispatch, for-in, ARC cleanup                                                                 |
| 12-HW | Hardware checkpoint                                  | Full system on nRF52833, flash + run, verify all output                                                            |
| 13    | Slab auto-count verification                         | Inspect generated `OZ_SLAB_DEFINE` counts, over-allocate in QEMU to confirm ENOMEM, file issue if counts are wrong |
| 14    | Multi-file header dependencies                       | cross-file #import, forward declarations                                                                           |
| 15    | Deep inheritance (4+ levels)                         | field embedding, super calls, class ID ordering                                                                    |
| 16    | Stress: 8+ classes, 3 protocols, 20+ methods         | full dispatch table, build time, binary size check                                                                 |
| 16-HW | Final hardware checkpoint                            | Full stress build on nRF52833, flash/RAM budget report, Rodrigo flashes                                            |

Each step = one `west build`. If it fails due to the transpiler, an issue is filed.

---

## Agent: MAINTAINER

### Identity

The transpiler developer. Deep knowledge of the Clang AST, the three-pass pipeline (collect → resolve → emit), Jinja2 templates, and the PAL. Fixes issues reported by DEV and QA.

### CLAUDE.md for MAINTAINER (objective-z repo)

```markdown
# CLAUDE.md

(Keep existing CLAUDE.md content, then append:)

## MAINTAINER Agent Role

You are MAINTAINER — responsible for fixing transpiler issues reported
in the px-app repository.

## Shared Files (in sibling repo: ../px-app/)

| File              | You                                        | Purpose                                |
| ----------------- | ------------------------------------------ | -------------------------------------- |
| `issues/OZ-*.md`  | READ, UPDATE status/discussion/resolution  | Issue tracker                          |
| `reviews/QR-*.md` | READ (act on FAIL/NEEDS_FOLLOWUP findings) | QA feedback                            |
| `STATUS.md`       | WRITE                                      | Tell DEV + QA what fixes are available |
| `WORKAROUNDS.md`  | READ                                       | Understand what DEV had to do          |

## Workflow

### Polling (do this at the start of every work session)

1. List `../px-app/issues/` — read any file with `status: open`
2. List `../px-app/reviews/` — read any QR with `verdict: FAIL` or `NEEDS_FOLLOWUP`
3. Read `../px-app/WORKAROUNDS.md` to understand DEV's pain points
4. Sort work: [URGENT] issues first, then QA FAIL findings, then by date

### Per-issue flow

1. Read the issue file fully (input snippet, observed, expected)
2. Read the related WORKAROUNDS.md entry if one exists
3. Reproduce: create a minimal test fixture from the input snippet
4. If fix is clear:
   a. Implement in the transpiler (collect.py / resolve.py / emit.py / templates)
   b. Add golden-file test in tools/oz_transpile/tests/golden/
   c. Add behavior test in tests/behavior/ if runtime behavior is affected
   d. Ensure transpiler stdout/stderr gives clear feedback for this feature:
   - Success: `--verbose` should log the transform applied
   - Failure: `--strict` should emit an actionable diagnostic
     e. Update docs/LIMITATIONS.md if a limitation is being removed
     f. Run full test suite: `just test-transpiler && just test-behavior && just test-adapted`
     g. Commit: `fix(transpiler): <description> — closes OZ-NNN`
     h. Update issue file: set `status: resolved`, fill resolution section, add commit hash
     i. Update `../px-app/STATUS.md`: add fix to "Latest available fixes", add notes
5. If clarification needed:
   a. Update issue file: set `status: in-progress`, `assigned-to: MAINTAINER`
   b. Add question in Discussion section with timestamp
   c. STOP work on this issue — wait for Rodrigo's answer
   d. After answer appears: resume from step 4

### Responding to QA reviews

- `PASS` / `PASS_WITH_NOTES`: read notes, incorporate suggestions into future work
- `NEEDS_FOLLOWUP`: QA has filed new OZ-NNN issues — treat them as normal issues
- `FAIL`: drop current work and address the QA finding immediately
  (QA FAIL means a regression or broken error path — this is urgent)

### Quality gates

Every fix must pass before marking resolved:

- `just test-transpiler` — all transpiler unit/golden tests pass
- `just test-behavior` — all compiled behavior tests pass
- `just test-adapted` — all adapted upstream tests pass
- New golden-file test specifically covering the issue's input snippet
- LIMITATIONS.md updated if applicable

## Priority Order

1. QA `FAIL` findings (regressions)
2. `[URGENT]` issues from DEV (blocked)
3. QA `NEEDS_FOLLOWUP` issues (quality)
4. Normal open issues by date
```

---

## Agent: QA

### Identity

A quality engineer focused on transpiler output quality, error messaging, developer experience, and regression prevention. QA does not build applications (that's DEV) or implement fixes (that's MAINTAINER). QA's job is to ensure every fix makes the transpiler **better to use**, not just functionally correct.

### What QA catches that others miss

| Concern                            | DEV checks? | MAINTAINER checks? | QA checks?        |
| ---------------------------------- | ----------- | ------------------ | ----------------- |
| App builds after fix               | ✅          | —                  | —                 |
| Unit/golden tests pass             | —           | ✅                 | ✅ (re-run)       |
| Generated C is readable/debuggable | —           | —                  | ✅                |
| Error messages are actionable      | —           | —                  | ✅                |
| `--verbose` output is useful       | —           | —                  | ✅                |
| `--strict` catches bad input       | —           | —                  | ✅                |
| LIMITATIONS.md matches reality     | —           | partial            | ✅                |
| Edge cases beyond the happy path   | —           | partial            | ✅                |
| Regression in unrelated features   | —           | ✅ (test suite)    | ✅ (manual probe) |
| Generated C compiles warning-free  | —           | —                  | ✅                |
| Consistent naming/style in output  | —           | —                  | ✅                |

### QA's scope — the five checks

**1. Generated C Quality**
Does the output look like what a competent C developer would write? Meaningful variable names, not `_tmp_0`. Comments for non-obvious transforms. No unnecessary casts. No dead code. Compiles with `-Wall -Wextra` without warnings.

**2. Error Messaging (stdout/stderr)**
When the transpiler encounters unsupported input or malformed code, does it tell the developer what went wrong and what to do instead? Test with deliberately bad input related to the fix. Verify `--verbose` adds useful diagnostics. Verify `--strict` mode rejects what it should.

**3. LIMITATIONS.md Accuracy**
After MAINTAINER's fix, does LIMITATIONS.md still match reality? If a limitation was removed, is it gone from the doc? If a new caveat was introduced, is it documented? Cross-reference every entry against actual transpiler behavior.

**4. Test Coverage**
Did MAINTAINER's golden test cover the edge cases? QA probes boundaries: empty inputs, single-element cases, deeply nested structures, mixed features. If coverage is thin, QA files a quality issue.

**5. Regression Probe**
Beyond the automated test suite (which MAINTAINER already runs), QA manually tests adjacent features. If the fix touched `collect.py`'s statement walker, QA re-tests for-in loops, blocks, and ARC scope even if those tests passed — because the change could have subtle interaction effects that aren't covered by existing tests.

### CLAUDE.md for QA (objective-z repo)

```markdown
# CLAUDE.md

(Keep existing CLAUDE.md content, then append:)

## QA Agent Role

You are QA — responsible for reviewing every transpiler fix for code quality,
usability, error messaging, and regressions. You work in your own read-only
clone of objective-z (`~/projects/objective-z-qa/`) and write review reports
to the px-app sibling repo.

## Setup

You have a separate clone: `~/projects/objective-z-qa/`.
Before each review, run `git pull origin main` to get MAINTAINER's latest commits.
You NEVER modify files in this repo — it is read-only for you.

## Shared Files (in sibling repo: ../px-app/)

| File              | You                                           | Purpose             |
| ----------------- | --------------------------------------------- | ------------------- |
| `issues/OZ-*.md`  | READ; WRITE new quality issues (filed-by: QA) | Issue tracker       |
| `reviews/QR-*.md` | WRITE (one per reviewed fix)                  | Your primary output |
| `STATUS.md`       | READ (discover which fixes need review)       | Fix availability    |
| `WORKAROUNDS.md`  | READ (understand DEV's pain)                  | Context for reviews |
| `CHANGELOG.md`    | READ (understand what DEV is building)        | Context             |

## Workflow

### Polling (do this at the start of every work session)

1. Read `../px-app/STATUS.md` — check "Latest available fixes" for entries
   without a QA column value
2. These are fixes that need your review — process them in order

### Per-fix review

For each fix that needs review:

1. Read the original issue file (`../px-app/issues/OZ-NNN.md`)
2. Read `../px-app/WORKAROUNDS.md` for related workaround context
3. Run `git pull origin main` to get MAINTAINER's latest commits
4. Run the five checks (below)
5. Write a review report: `../px-app/reviews/QR-NNN.md`
6. Update the original issue: set `qa-review: QR-NNN`
7. If verdict is NEEDS_FOLLOWUP: file new `../px-app/issues/OZ-NNN.md` for each finding
   with `filed-by: QA`

### The Five Checks

#### Check 1: Generated C Quality

- Transpile the issue's input snippet (or the golden-file test input)
- Read the generated `.c` and `.h` files
- Verify: meaningful names, no dead code, no unnecessary casts, comments
  where transforms are non-obvious
- Compile with `gcc -Wall -Wextra -Werror` — must produce zero warnings
- Compare against what a human C developer would write

#### Check 2: Error Messaging

- Feed deliberately malformed input related to this feature
  (e.g., if fix adds switch support, test: empty switch, switch in block,
  switch with fall-through, switch in nested scope)
- Capture transpiler stdout and stderr
- Verify: error message names the source file and line, describes the problem,
  suggests a fix or workaround
- Test with `--verbose`: does it add useful diagnostic info?
- Test with `--strict`: does it reject what it should?
- Test without --strict: does it degrade gracefully (warning, not crash)?

#### Check 3: LIMITATIONS.md Accuracy

- Read `docs/LIMITATIONS.md`
- If this fix removes a documented limitation: verify it's removed from the doc
- If this fix adds a new caveat: verify it's documented
- Spot-check 2-3 other limitations to confirm they still hold
  (MAINTAINER's fix may have accidentally changed behavior for listed items)

#### Check 4: Test Coverage

- Read MAINTAINER's golden-file test for this fix
- Identify edge cases not covered:
  - Empty/minimal input
  - Maximum complexity input
  - Mixed with other features (e.g., switch inside a block, switch with ARC)
  - The input from the original issue's workaround (does the transpiler
    handle both the ideal ObjC AND the workaround ObjC?)
- If coverage is thin, file a quality issue

#### Check 5: Regression Probe

- Identify which transpiler files were changed (collect.py? emit.py? templates?)
- Run `just test-transpiler && just test-behavior && just test-adapted`
  to confirm full suite passes
- Manually test 2-3 adjacent features that share code paths with the fix
  (e.g., if collect.py's \_walk_stmt changed, manually test for-in, blocks, ARC scope)
- If a regression is found, file an [URGENT] issue immediately

### Verdicts

- **PASS**: Fix is clean across all five checks. No findings.
- **PASS_WITH_NOTES**: Fix works but has minor suggestions (style, naming,
  additional test ideas). Notes go in the review report for MAINTAINER to read.
- **NEEDS_FOLLOWUP**: One or more findings need new issues. QA files them.
  The original fix is usable but has quality gaps.
- **FAIL**: Regression found, or error messaging is actively misleading,
  or generated C doesn't compile. QA files an [URGENT] issue.
  This is rare — only for things that would hurt DEV.

### Issue Filing Rules (for QA-originated issues)

- **QA uses even IDs: OZ-002, OZ-004, OZ-006, ...** (DEV uses odd IDs)
- Check existing files in issues/ directory to find the next even number
- Set `filed-by: QA`
- NOT typically [URGENT] unless it's a regression
- Categories QA files:
  - `[QA:REGRESSION]` — fix broke something else
  - `[QA:ERROR_MSG]` — error message missing or misleading
  - `[QA:COVERAGE]` — test coverage gap
  - `[QA:GENERATED_C]` — generated output quality issue
  - `[QA:DOCS]` — LIMITATIONS.md or README out of sync

## Quality Bar

You are not a gatekeeper — DEV doesn't wait for you. Your reviews run
in parallel with DEV's verification. Your value is catching things that
would bite DEV in step N+3 or bite a future user of the transpiler.

Focus on actionable findings. "This variable name could be better" is a note.
"This error message says 'internal error' with no context" is a finding.
"This fix broke for-in loops" is an [URGENT] issue.
```

---

## How Rodrigo Operates

Rodrigo is the human in the loop. With three agents and the file-based protocol, Rodrigo's role is: **answering technical questions**, **reviewing commits**, and **reading QA reports** (which often surface design decisions worth discussing).

### Rodrigo's responsibilities

1. **Bootstrap both repos** — create `px-app/` scaffolding, initialize shared files
2. **Launch all three agents** with Claude Code
3. **Answer MAINTAINER questions** — check `issues/` for files with `status: in-progress` that have unanswered questions. Edit the file directly.
4. **Review MAINTAINER commits** — run tests, approve, push to remote
5. **Read QA reviews** — `reviews/QR-*.md` often surface design tensions worth discussing
6. **Flash hardware at [HW] checkpoints** — when DEV reports a successful nrf52833dk build, Rodrigo flashes the board and pastes serial output back into DEV's chat (e.g., "the generated C works but the naming convention is inconsistent with existing output")

### What Rodrigo does NOT need to do

- ~~Tell MAINTAINER to check for issues~~ → MAINTAINER polls `issues/`
- ~~Tell DEV to pull fixes~~ → DEV polls `STATUS.md`
- ~~Tell QA to review fixes~~ → QA polls `STATUS.md`
- ~~Relay information between agents~~ → shared files handle it
- ~~Track workaround state~~ → `WORKAROUNDS.md` handles it
- ~~Track QA status~~ → `reviews/` and `qa-review` field handle it

### Rodrigo's Terminal Layout

```
┌──────────────────┬──────────────────┬──────────────────┐
│  Terminal 1: DEV │  Terminal 2:     │  Terminal 3: QA  │
│  ~/px-app        │  MAINTAINER      │  ~/objective-z-qa│
│                  │  ~/objective-z   │                  │
│  checks STATUS   │  polls issues/   │  polls STATUS    │
│  "Build step 3"  │  "Fixing OZ-001" │  "Reviewing      │
│  "Filed OZ-005"  │  "Question..."   │   OZ-001 fix..." │
├──────────────────┴──────────────────┴──────────────────┤
│  Terminal 4: Rodrigo                                    │
│  Watches for in-progress issues with questions          │
│  Reads QA reviews for design decisions                  │
│  Reviews MAINTAINER commits                             │
└─────────────────────────────────────────────────────────┘
```

### Rodrigo override commands

| Command                                     | To         | When                                  |
| ------------------------------------------- | ---------- | ------------------------------------- |
| `"Prioritize OZ-NNN"`                       | MAINTAINER | Escalation beyond [URGENT]            |
| `"Skip step N, move to N+1"`                | DEV        | Strategic decision to defer           |
| `"Apply this workaround: ..."`              | DEV        | Rodrigo knows a workaround            |
| `"Hold off, I'm refactoring"`               | MAINTAINER | Rodrigo making structural changes     |
| `"Waive QA for OZ-NNN"`                     | QA         | Low-risk fix, skip review             |
| `"QA: focus on error messaging this round"` | QA         | Steer QA attention                    |
| `"Flashed nrf52833dk, serial output: ..."`  | DEV        | After [HW] checkpoint flash           |
| `"nrf52833dk flash failed: ..."`            | DEV        | Hardware issue for DEV to investigate |

---

## Synchronization Protocol

Three agents, four shared files, minimal Rodrigo involvement.

```
                    ┌──────────────────┐
                    │     Rodrigo      │
                    │  (answers,       │
                    │   reviews,       │
                    │   reads QA)      │
                    └──┬─────┬─────┬───┘
                       │     │     │
              answers  │     │     │ reads QA
             questions │     │     │ reviews
                       ▼     │     ▼
┌────────────────┐     │  ┌────────────────┐  ┌──────────────────┐
│      DEV       │     │  │  MAINTAINER    │  │       QA         │
│  (px-app/)     │     │  │ (objective-z/) │  │ (objective-z-qa/)│
└──────┬─────────┘     │  └──────┬─────────┘  └──────┬───────────┘
       │               │         │                    │
       │ writes:       │         │ writes:            │ writes:
       │  issues/ (odd)│         │  STATUS.md         │  reviews/
       │  WORKAROUNDS  │         │                    │  issues/ (even)
       │  CHANGELOG    │         │ reads:             │
       │               │         │  issues/           │ reads:
       │ reads:        │         │  reviews/          │  STATUS.md
       │  STATUS.md    │         │  WORKAROUNDS       │  issues/
       │  reviews/     │         │                    │  WORKAROUNDS
       │               │         │                    │  CHANGELOG
       │     ┌─────────┴─────────┴────────────────────┘
       └────►│          px-app/ shared files           │
             │  issues/  reviews/  STATUS  WORKAROUNDS │
             └─────────────────────────────────────────┘
```

### Issue lifecycle — full cycle with QA (zero Rodrigo involvement)

```
1.  DEV builds step N → transpiler fails
2.  DEV creates issues/OZ-007.md (status: open)
3.  DEV creates WORKAROUNDS.md WA-005 entry
4.  DEV applies workaround, continues to step N+1
5.  MAINTAINER polls issues/, finds OZ-007 (status: open)
6.  MAINTAINER implements fix, runs tests, commits
7.  MAINTAINER updates OZ-007.md (status: resolved, commit: xyz)
8.  MAINTAINER appends to STATUS.md (OZ-007 fix available)
    ┌─────────────────────────────┬─────────────────────────────┐
    │  DEV path (parallel)        │  QA path (parallel)         │
    ├─────────────────────────────┼─────────────────────────────┤
    │ 9a. reads STATUS.md         │ 9b. reads STATUS.md         │
    │ 10a. west update            │ 10b. git pull origin main   │
    │ 11a. reverts WA-005         │ 11b. runs five checks       │
    │ 12a. rebuilds, verifies     │ 12b. writes reviews/QR-003  │
    │ 13a. status: verified       │ 13b. updates qa-review field│
    └─────────────────────────────┴─────────────────────────────┘
14. MAINTAINER reads QR-003 notes (if any) for future reference
15. If QA verdict is NEEDS_FOLLOWUP: new OZ-NNN issues enter the pipeline
```

### Issue lifecycle — with Rodrigo involvement

```
1-4.  Same as above
5.    MAINTAINER polls issues/, finds OZ-007 (status: open)
6.    MAINTAINER needs clarification → updates OZ-007.md:
      - status: in-progress
      - Discussion: adds question with timestamp
7.    Rodrigo sees in-progress issue, edits Discussion with answer
8.    MAINTAINER reads answer, implements fix
9-15. Same as full cycle above
```

---

## Bootstrap Steps

### 1. Create px-app repository

```bash
mkdir -p ~/projects/px-app/src/models ~/projects/px-app/src/drivers \
         ~/projects/px-app/src/services ~/projects/px-app/src/protocols \
         ~/projects/px-app/issues ~/projects/px-app/reviews
cd ~/projects/px-app
git init
```

Create `west.yml`, `CMakeLists.txt`, `prj.conf` as shown in Repository Layout.

Create the skeleton `src/main.m` (DEV step 0 — proves the toolchain before any app code):

```objc
/* Step 0 — skeleton main. Proves module import, transpiler, QEMU boot. */

#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>

int main(void)
{
    printk("px-app booted\n");
    return 0;
}
```

### 2. Create QA clone

```bash
cd ~/projects
git clone objective-z objective-z-qa
```

QA runs `git pull origin main` before each review session.

### 3. Create shared protocol files

Create `STATUS.md`:

```markdown
# Transpiler Status

## Latest available fixes

| Issue | Title | Commit | Date | QA  |
| ----- | ----- | ------ | ---- | --- |

## Pending (in progress)

| Issue | Title | ETA |
| ----- | ----- | --- |

## Notes to DEV

(none)
```

Create `WORKAROUNDS.md`:

```markdown
# Active Workarounds

(none yet)

# Resolved Workarounds

(none yet)
```

Create `CHANGELOG.md`:

```markdown
# px-app Build Changelog

## Build Log

(DEV logs each successful build step here)
```

Create `issues/TEMPLATE.md` and `reviews/TEMPLATE.md` with the templates shown above.

### 4. Initialize Zephyr workspace

```bash
cd ~/projects/px-app
west init -l .
west update
```

### 5. Verify step 0 (skeleton main.m)

```bash
# QEMU
cd ~/projects/px-app
west build -b mps2/an385
west build -t run
# Should print "px-app booted" and exit

# Hardware (compile + link only — Rodrigo flashes)
west build -b nrf52833dk/nrf52833 -p
arm-none-eabi-size build/zephyr/zephyr.elf
# Record baseline: text/data/bss sizes for tracking growth
```

If QEMU fails, the toolchain or module import is broken.
If nrf52833dk fails, check that the Zephyr SDK has the ARM toolchain and
the nRF HAL module is pulled. Fix before launching agents.

Rodrigo flashes the nrf52833dk build and verifies "px-app booted" on serial
(115200 baud, `/dev/tty.usbmodem*` on macOS).

### 6. Create CLAUDE.md files

- Copy the DEV CLAUDE.md content into `px-app/CLAUDE.md`
- Append the MAINTAINER section to `objective-z/CLAUDE.md`
- Append the QA section to `objective-z-qa/CLAUDE.md`

### 7. Launch agents

```bash
# Terminal 1 — DEV
cd ~/projects/px-app && claude
# Prompt: "You are DEV. Read CLAUDE.md. Step 0 is done. Start building step 1."

# Terminal 2 — MAINTAINER
cd ~/projects/objective-z && claude
# Prompt: "You are MAINTAINER. Read CLAUDE.md. Poll ../px-app/issues/ for open issues."

# Terminal 3 — QA
cd ~/projects/objective-z-qa && claude
# Prompt: "You are QA. Read CLAUDE.md. Poll ../px-app/STATUS.md for fixes needing review."
```

### 8. Rodrigo monitoring

```bash
# Issues needing Rodrigo's answer:
grep -rl "status: in-progress" ~/projects/px-app/issues/OZ-*.md 2>/dev/null

# QA reviews worth reading:
grep -rl "verdict: FAIL\|verdict: NEEDS_FOLLOWUP" ~/projects/px-app/reviews/QR-*.md 2>/dev/null

# Watch everything:
fswatch ~/projects/px-app/issues/ ~/projects/px-app/reviews/ ~/projects/px-app/STATUS.md
```

---

## Constraints & Design Decisions

**Why separate repos?** Claude Code agents have file-system scope. Separate repos give each agent a clear boundary. The module import via `west.yml` is how real Zephyr projects consume libraries — production-realistic.

**Why an issues directory not a single file?** One file per issue makes operations atomic. DEV creates `OZ-005.md` while MAINTAINER updates `OZ-003.md` while QA reads `OZ-001.md` — no collision.

**Why STATUS.md?** Eliminates the most frequent Rodrigo intervention. DEV and QA both poll it autonomously.

**Why WORKAROUNDS.md?** Surfaces technical debt. Gives MAINTAINER fix-design context. Gives QA review context. Gives DEV a mechanical revert checklist.

**Why QA runs in parallel, not as a gate?** If QA gated MAINTAINER → DEV, every fix would take longer. DEV doesn't wait for QA. QA's findings either become new issues (normal pipeline) or inform future MAINTAINER work (notes). The only exception is `FAIL` (regression), which triggers an urgent issue that MAINTAINER must address — but this is rare and genuinely urgent.

**Why QA works in the objective-z repo?** QA needs to run the transpiler, inspect generated output, test error messages, and re-run the test suite. All of this lives in objective-z.

**Why QA gets a separate clone?** MAINTAINER is actively editing `emit.py` while QA runs `just test-transpiler`. If they share a working tree, QA could test half-written code. A separate clone (`objective-z-qa`) that QA `git pull`s before each review gives clean isolation. QA writes reviews to `../px-app/reviews/` — it never modifies the objective-z code.

**Why DEV writes idiomatic ObjC first, even for known limitations?** Every known limitation is a chance to evaluate the transpiler's error message quality. If DEV jumps straight to the workaround, that signal is lost. Writing the natural ObjC, capturing the error, then applying the workaround produces free QA data points for error messaging — which is exactly what QA reviews.

**Why a skeleton main.m before step 1?** The first build should test the toolchain, not the application. If `west build` fails on a bare `printk` + `return 0`, the problem is module import, Clang detection, or Zephyr configuration — not the transpiler. Fixing this before launching agents avoids wasting agent time on environment issues.

**Why odd/even issue IDs?** DEV and QA both create `OZ-NNN.md` files. If both check the directory simultaneously and see `OZ-005` as the latest, they'd both create `OZ-006`. Odd for DEV, even for QA eliminates the collision with zero coordination overhead — each agent only needs to know its own parity.

**Why `west.yml` uses a local path?** During local development, DEV's `west update` needs to see MAINTAINER's commits immediately — not after a GitHub push. Pointing `west.yml` at MAINTAINER's local clone (`url: /Users/rodrigo/projects/objective-z`) eliminates the round-trip. Switch to the remote URL for CI.

**Why a sensor system?** Canonical Zephyr use case. Exercises inheritance, protocols, collections, state machines, zbus, singletons, multi-file builds — every transpiler feature. On the nRF52833 DK, the system can use real GPIO (4 LEDs, 4 buttons) instead of printk-only stubs.

**Why dual-target (QEMU + nRF52833)?** QEMU gives fast iteration — every build step runs there. But QEMU has effectively unlimited memory, so bloated generated C never fails. The nRF52833's 512KB flash / 128KB RAM is a real constraint: if the transpiler generates unnecessary dispatch tables, redundant struct copies, or oversized slabs, the link will fail. Periodic hardware checkpoints (steps 0-HW, 4-HW, 8-HW, 12-HW, 16-HW) catch code size issues that QEMU hides. Rodrigo handles the physical flash — agents can't access USB.

**Why DEV always applies workarounds?** Avoids deadlock. DEV never waits for MAINTAINER. The workaround + original code pair is itself valuable test data.

**Why not the Anthropic API?** Claude Code gives each agent a live shell — `west build`, `clang`, `pytest`, `qemu`. The file-based protocol handles three-way sync without orchestration code. Revisit if empirical data shows a bottleneck.
