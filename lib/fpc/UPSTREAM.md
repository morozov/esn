# Vendored FPC RTL slice — provenance and local deltas

This tree is a vendored subset of Free Pascal's `packages/rtl-console/`
and `packages/rtl-unicode/src/inc/` from upstream trunk. It exists
because stock FPC 3.2.2 lacks the enhanced (Unicode) Video API
(`TEnhancedVideoCell`, `EnhancedVideoBuf`, `InitEnhancedVideo`,
`StringDisplayWidth`, …) — see [Spec 001](../../specs/001-enhanced-video-unit-port.md)
for the port plan.

## Upstream

- Project: <https://gitlab.com/freepascal.org/fpc>
- Branch: `main`
- Pulled on: 2026-04-18
- Anchor commit for videoh.inc at pull time: `339d0d83`
  (latest change to `packages/rtl-console/src/inc/videoh.inc`
  that pre-dates this pull).

File-by-file source paths, relative to the upstream repository root:

| Vendored path                                        | Upstream path                                                 | Lines |
|------------------------------------------------------|---------------------------------------------------------------|------:|
| `rtl-console/src/inc/videoh.inc`                     | `packages/rtl-console/src/inc/videoh.inc`                     |   271 |
| `rtl-console/src/inc/video.inc`                      | `packages/rtl-console/src/inc/video.inc`                      |   863 |
| `rtl-console/src/unix/unicodevideo.pp`               | `packages/rtl-console/src/unix/video.pp` (renamed)            |  1520 |
| `rtl-console/src/unix/unixkvmbase.pp`                | `packages/rtl-console/src/unix/unixkvmbase.pp`                |    58 |
| `rtl-console/src/win/unicodevideo.pp`                | `packages/rtl-console/src/win/video.pp` (renamed)             |   706 |
| `rtl-unicode/src/inc/graphemebreakproperty.pp`       | `packages/rtl-unicode/src/inc/graphemebreakproperty.pp`       |   182 |
| `rtl-unicode/src/inc/graphemebreakproperty_code.inc` | `packages/rtl-unicode/src/inc/graphemebreakproperty_code.inc` |   511 |
| `rtl-unicode/src/inc/eastasianwidth.pp`              | `packages/rtl-unicode/src/inc/eastasianwidth.pp`              |    57 |
| `rtl-unicode/src/inc/eastasianwidth_code.inc`        | `packages/rtl-unicode/src/inc/eastasianwidth_code.inc`        |   300 |

All files retain their upstream LGPL-with-linking-exception headers
verbatim. Do **not** remove or reflow the copyright notices.

## Local deltas

Every local change MUST be listed here. The policy (from Spec 001)
is **delete-only** for pruning — no renames, no reformatting, no
reordering — so a diff against upstream stays readable. Any other
kind of change is a *tracked patch* and must be called out explicitly.

### Deletions

None yet. Pruning of unused upstream platform drivers (Amiga, OS/2,
GO32V2, NetWare, BeOS, MorphOS, Wii, macOSClassic) and any symbols
rendered dead by the platform cull is deferred to Spec 001 Step 4.

### Renames

- `rtl-console/src/unix/video.pp` → `unicodevideo.pp`
- `rtl-console/src/win/video.pp` → `unicodevideo.pp`
- Inside those files, the unit declaration was changed from
  `unit video;` / `unit Video;` to `unit UnicodeVideo;`.

Why: the shadowing approach (keep the unit name as `Video` and
override the RTL's copy via `-Fu`) collides with stock FPC 3.2.2
`Keyboard.ppu` / `Mouse.ppu`, which carry an interface-checksum
reference to the stock `Video.ppu`. Renaming sidesteps the conflict
entirely; Keyboard and Mouse keep resolving `uses Video` to the
unchanged RTL, and ESN code says `uses UnicodeVideo, Keyboard`.

Refresh cost: one sed step per platform file. Trivial.

### Tracked patches (non-deletion changes)

#### P1 — `rtl-console/src/unix/unicodevideo.pp` : disable kitty-keyboard probe

Upstream enables the kitty-keyboard protocol unconditionally on init
by emitting `CSI > 31 u`, and disables it on done with `CSI < u`.
Stock FPC 3.2.2 `Keyboard` cannot parse the terminal's reply — those
bytes are consumed by `GetKeyEvent` as a spurious event, so the
first key-wait returns immediately without a real keystroke.

**Fix**: both blocks deleted and replaced with an ESN-marked comment:

- Approximate line 1335 (was):

  ```pascal
  {$ifndef HAIKU}
       envInput := LowerCase(fpgetenv('TV_INPUT'));
       if (envInput = '') or (envInput = 'kitty') then
         SendEscapeSeq(#27'[>31u');
  {$endif HAIKU}
  ```

- Approximate line 1349 (was):

  ```pascal
  {$ifndef HAIKU}
    SendEscapeSeq(#27'[<u');
  {$endif HAIKU}
  ```

Both are pure deletion; this is really in the "Deletions" category
but grouped with P2 here for readability.

#### P2 — `rtl-console/src/unix/unicodevideo.pp` : revert xterm cursor-style escapes to stock 3.2.2

Upstream's `term_codes_xterm` table uses DECSCUSR sequences to force
a *steady* cursor style (`[4 q` for underline, `[2 q` for block):

```pascal
#27'[?25h'#27'[4 q',                               {cursor visible, underline}
#27'[?25h'#27'[2 q',                               {cursor visible, block}
```

On macOS Terminal.app (and most other emulators with cursor blinking
enabled by default), the steady style paints a bright cursor block
or underline on top of whatever glyph is at (CursorX, CursorY)
after `UpdateScreen`. Stock FPC 3.2.2 uses `CSI ? 12 ; 25 h`, which
enables blink + visibility and leaves cursor *style* at the terminal
default. A blinking cursor lands in its OFF phase half the time and
reads as visually absent.

**Fix**: reverted both entries to stock 3.2.2 bytes verbatim:

```pascal
#$1B#$5B#$3F#$31#$32#$3B#$32#$35#$68,              {cursor visible, underline}
#$1B#$5B#$3F#$31#$32#$3B#$32#$35#$68,              {cursor visible, block}
```

This is a **replace**, not a delete, and therefore violates the
delete-only pruning policy. It is recorded here as a tracked patch.
On refresh:

1. Check whether upstream still uses DECSCUSR for these two entries.
2. If so, re-apply this patch.
3. If upstream has moved back to `[?12;25h` or to an opt-in env var,
   drop this patch.

Verification: `tmp/probes/diff-esc.sh tmp/box tmp/utf8box` must
report identical escape classes between the classic `box.pas` and
UTF-8 `utf8box.pas` builds.

#### P3 — `rtl-console/src/win/unicodevideo.pp` : mark East-Asian Wide cells with `COMMON_LVB_LEADING_BYTE`/`TRAILING_BYTE`

Upstream's `SysUpdateScreen` packs each `EnhancedVideoBuf` cell into
one `TCharInfo` (one UTF-16 code unit) and calls
`WriteConsoleOutputW`.  The classic Windows console renders that
buffer cell-for-cell at single width, regardless of the codepoint's
East Asian Width property.  A wide CJK glyph (e.g. `中`) therefore
draws in one cell, with whatever was in the next cell (often a space
or border glyph) visible immediately to its right — column alignment
in the panel listing breaks on the first wide character.

**Fix**: ESN-added post-pass between LineBuf packing and the
`WriteConsoleOutputW` call.  For each wide cell (`GetEastAsianWidth`
returns `eawW` or `eawF`), set `COMMON_LVB_LEADING_BYTE` on the
attribute, copy the same UnicodeChar into the next cell, and set
`COMMON_LVB_TRAILING_BYTE` on its attribute.  The console then
treats the pair as a single 2-cell glyph.

Block lives at `SysUpdateScreen`, immediately after the LineBuf
packing loop, ~24 lines starting with `BufCounter := 0;`/
`LineCounter := 1;` and the comment `{ Mark East Asian Wide chars
with COMMON_LVB_LEADING_BYTE / TRAILING_BYTE ... }`.

This is a logic *addition*, not a modification of upstream lines.
On refresh:

1. Check whether upstream has added native wide-char marking to
   `SysUpdateScreen` (e.g. via `WriteConsoleOutputW` flags or a
   newer Windows-console API path).
2. If yes, drop this patch.
3. If no, re-apply the block at the same location.

Verification: visual inspection on Windows of a directory containing
CJK filenames (e.g. `中文.txt`).  The column-1/column-2 separator
must land at the panel's column-2 boundary, not shifted right.

#### Caveat — astral codepoints render as space on Windows

`SysUpdateScreen` packs `ExtendedGraphemeCluster` into a single
`WideChar` cell with the substitution

```pascal
if Length(...ExtendedGraphemeCluster) = 1 then
  LineBuf[BufCounter].UniCodeChar := ...ExtendedGraphemeCluster[1]
else
  LineBuf[BufCounter].UniCodeChar := ' ';
```

i.e. surrogate pairs (U+10000+), combining sequences, ZWJ sequences,
and regional-indicator flags are silently replaced with `' '`.

This is upstream behaviour, inherent to the legacy
`CHAR_INFO`/`WriteConsoleOutputW` API (UTF-16 code unit per cell).
The Unix path (`OutData(transform(chattr.ExtendedGraphemeCluster))`)
emits the full cluster, so platforms diverge: 😀 in a filename
shows on Linux/macOS but blanks on Windows.  ESN's primary content
(ZX Spectrum filenames) is BMP-only so this rarely bites in
practice.  A real fix would require a ConPTY VT-sequence path and
is out of scope for this slice.

## Build integration

Consumers point FPC at this tree via:

```
-Fulib/fpc/rtl-console/src/unix        { or .../src/win on Windows }
-Filib/fpc/rtl-console/src/inc
-Fulib/fpc/rtl-unicode/src/inc
-Filib/fpc/rtl-unicode/src/inc
```

Build artefacts (`*.ppu`, `*.o`) MUST NOT be committed; `lib/fpc/` is
source-only.

## Refresh procedure

1. Pull the target upstream tree into `tmp/fpc-upstream/`:

   ```
   curl -fsSL "https://gitlab.com/freepascal.org/fpc/source/-/raw/<ref>/<path>" \
     -o tmp/fpc-upstream/<path>
   ```

   Use the file list under "Upstream" above.

2. Diff each upstream file against the vendored copy (after applying
   the rename reverse-sed `UnicodeVideo` → `video` to make the
   filename-level diff meaningful).

3. Reconcile deletions: prior pruning deletions SHOULD be re-applied.
   Tracked patches (P1, P2, …) SHOULD be re-evaluated against the
   new upstream.

4. Update the "Anchor commit" and "Pulled on" fields at the top of
   this file.

5. Run `tmp/probes/diff-esc.sh tmp/box tmp/utf8box` and confirm
   escape-class parity with the classic baseline.
