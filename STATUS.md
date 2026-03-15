# Transpiler Status

## Latest available fixes

| Issue  | Title                                         | Commit  | Date       | QA      |
| ------ | --------------------------------------------- | ------- | ---------- | ------- |
| OZ-001 | Flatten subdirectory prefix in #include paths  | 37d3501 | 2026-03-15 | PASS_WITH_NOTES |
| OZ-002 | @synthesize bare form struct/accessor mismatch | 59ba7e7 | 2026-03-15 | pending |
| OZ-004 | File-scope static with ObjC type + nil init    | 59ba7e7 | 2026-03-15 | pending |
| OZ-006 | Diagnostics for unsupported constructs          | 59ba7e7 | 2026-03-15 | pending |
| OZ-008 | LIMITATIONS.md missing entries                  | 59ba7e7 | 2026-03-15 | pending |
| OZ-003 | Protocol dispatch __patched__ return cast       | 7401b87 | 2026-03-15 | PASS (QR-003) |
| OZ-005 | Protocol dispatch receiver var in return stmt   | 22d5233 | 2026-03-15 | pending |
| OZ-007 | User enum not collected for switch/case         | 8523e65 | 2026-03-15 | pending |
| OZ-009 | _is_user_enum not defined (stale copy)          | 8523e65 | 2026-03-15 | N/A |
| OZ-010 | LIMITATIONS.md switch/case entry inaccurate     | 8523e65 | 2026-03-15 | pending |
| OZ-012 | switch/case body not emitted                    | 5cc5558 | 2026-03-15 | pending |
| OZ-014 | LIMITATIONS.md switch/case entry fix             | 5cc5558 | 2026-03-15 | pending |
| OZ-011 | Quoted #include stripped (could not reproduce)  | N/A     | 2026-03-15 | pending |
| OZ-013 | C constructs stripped (could not reproduce)     | N/A     | 2026-03-15 | pending |

## Pending (in progress)

| Issue | Title | ETA |
| ----- | ----- | --- |

## Notes to DEV

- **OZ-001 fixed**: You can revert WA-001 and move files into subdirectories (`src/services/`, etc.). The transpiler now correctly flattens `#import "services/Foo.h"` to `#include "Foo_ozh.h"` in generated output.
- **OZ-002 fixed**: `@synthesize propName;` (bare form) now works — struct field and accessor match. A diagnostic warns to prefer the explicit form `@synthesize propName = _propName;`.
- **OZ-003 fixed**: Protocol dispatch with object return types now casts correctly (e.g., `(struct OZString *)OZ_SEND_name(...)`). You can use protocol dispatch for `OZString *`-returning methods now — remove WA-002.
- **OZ-004 fixed**: `static ClassName *var = nil;` is now transpiled correctly to `struct ClassName *var = NULL;`. The `nil`→`NULL` conversion is handled for GNUNullExpr and NullToPointer cast patterns.
- **OZ-006 addressed**: Diagnostics now warn when unsupported ObjC constructs are encountered (bare @synthesize, ObjC-typed statics with complex init).
- **OZ-005 fixed**: Protocol dispatch calls in `return` statements now correctly declare the receiver variable. You can use `return [ivar method];` with protocol-dispatched methods now — remove WA-003.
- **OZ-007 fixed**: User-defined C enums are now collected and emitted in the class header. Use `enum PXDeviceState` as the ivar type.
- **OZ-012 fixed**: `switch`/`case`/`default` statements are now fully emitted. DEV can use switch with enum constants — remove WA-004 completely.
- **OZ-008 fixed**: LIMITATIONS.md updated with @synthesize and file-scope static entries.
