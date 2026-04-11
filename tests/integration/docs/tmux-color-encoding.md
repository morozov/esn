# tmux color encoding in `capture-pane -e`

Investigation script: [`testing/investigate_t007_color.sh`](../investigate_t007_color.sh)

Run it to reproduce the two-mode comparison that revealed the root cause:

```
./testing/investigate_t007_color.sh
```

---

This document records the investigation into environment-dependent color
encoding in `tmux capture-pane -e`, which caused T007_02_mark_color to
produce different results on different machines.

## The symptom

`assert_rect_fg` returned `light-yellow` on the developer's machine (both
Ghostty and Terminal.app) but `yellow` in Claude's subprocess environment,
for the same screen cell. The test assertion used `yellow`, so it passed
locally for Claude but failed for the developer.

## Root cause

`tmux capture-pane -e` uses **delta encoding**: it emits only the SGR
attributes that *change* relative to the current accumulated state. It does
not reset all attributes at the start of each row.

In the ESN screen, the panel header on row 1 sets bold (`^[[1m`). This bold
attribute is never explicitly cleared before row 4 (the marked-file row).
`capture-pane -e` therefore emits just `^[[33m` (yellow foreground) for row
4, relying on bold being inherited from row 1.

The `_parse_ansi_colors` function in `testing/lib/app.sh` only processed
rows within the target range (`NR >= start_row`). It never saw the `^[[1m`
from row 1, so it treated bold as unset and returned `yellow` instead of
`light-yellow`.

In the developer's terminal environment, tmux emitted `^[[93m` (direct
high-intensity yellow) for the same cell rather than relying on inherited
bold. The parser handled `^[[93m` correctly and returned `light-yellow`. The
two environments produced different parser output for the same logical color.

## The chain of events

### 1. Application output

FPC's `Video` unit maps CGA palette entry 14 (bright yellow) to SGR
`^[[1;33;44m` — bold on, foreground yellow, background blue. This was
confirmed by `pipe-pane` capture of the raw bytes ESN writes to the pty.

### 2. tmux internal storage

tmux normalises the incoming SGR into per-cell attributes:
- bold = true
- fg = color 3 (yellow)
- bg = color 4 (blue)

### 3. `capture-pane -e` re-encoding (delta)

`capture-pane -e` serialises the grid using delta encoding. The header on
row 1 sets `^[[1m` (bold). Because bold is never cleared between row 1 and
row 4, `capture-pane -e` emits only `^[[33m` for the marked-file cell —
bold is considered already active.

In some terminal environments tmux instead emits `^[[93m` (high-intensity
yellow) for the same stored state, avoiding the dependency on inherited bold.
Both forms are correct ANSI; which one tmux chooses depends on terminal
feature negotiation not fully characterised here.

### 4. Parser bug

`_parse_ansi_colors` skipped all rows before `start_row`. It initialized
`bright = 0` and never saw the `^[[1m` from row 1, so for the `^[[33m`-form
environment it returned `yellow`. For the `^[[93m`-form environment it
correctly returned `light-yellow`.

## The fix

`_parse_ansi_colors` now processes **all rows from 1 to the end of the
target range**, accumulating `bright`, `cur_fg`, and `cur_bg` state as it
goes. Column counting and output are only performed for rows within the
target range. This makes the parser correct regardless of which encoding
form `capture-pane -e` uses.

The assertion was updated from `yellow` to `light-yellow` to match the
semantically correct value: CGA color 14 is bright yellow.

## Investigation script

`testing/investigate_t007_color.sh` runs the step-2 scenario and prints
two views side by side:

- **Mode 1** — `capture-pane -e` output (what the test harness sees),
  with the raw ANSI bytes for row 4 and the parsed foreground color grid.
- **Mode 2** — `pipe-pane` raw capture (what ESN actually writes to the
  pty), showing all SGR sequences in the update and the raw bytes around
  the marked-file area.

Comparing Mode 1 and Mode 2 reveals whether a discrepancy originates in
ESN's output or in tmux's storage and re-encoding step.
