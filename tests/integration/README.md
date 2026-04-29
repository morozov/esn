# ESN End-to-End Test Suite

End-to-end tests that drive the running FPC port binary and verify
behavior through terminal screen captures.

## Directory layout

```
testing/
  README.md          — this file
  run_tests.sh       — master test runner
  lib/
    common.sh        — assertions, logging, counters, lifecycle stubs
    app.sh           — ESN lifecycle and screen capture (tmux-based)
    timing.sh        — sleep durations (single source of truth)
  docs/
    tmux-color-encoding.md — how capture-pane -e encodes colors; why the
                             color parser scans all preceding rows
  cases/
    T001_startup.sh
    T002_navigation.sh
    …                — case files numbered TNNN, run in lexical order
  results/           — timestamped output directories (not committed)
```

## Prerequisites

- macOS 12 or later (Linux works with minor path adjustments)
- bash 4+ (`brew install bash`)
- tmux (`brew install tmux`)
- Built port binary at `$PROJECT_ROOT/bin/esn`
- For `--attached` mode only: Terminal.app with Accessibility access
  (System Settings → Privacy & Security → Accessibility)

## Running tests

```bash
# Run all tests
./run_tests.sh

# Run a single test case (prefix match on case ID)
./run_tests.sh --case=T016

# Open a Terminal.app window to observe the tmux session while tests run
./run_tests.sh --attached

# Write screen dumps to OUT_DIR on assertion failure
./run_tests.sh --dump

# Verbose output (print each case script path as it runs)
./run_tests.sh --verbose
```

All tests run inside a detached tmux session. `--attached` opens a
Terminal.app window that mirrors the session for visual observation;
it has no effect on assertion results.

## How tests work

Each file in `cases/` is a self-contained bash script that defines:

- `setup()` — start ESN in a known state via `app_reset [COLS [ROWS]]`
- `run()` — send keystrokes, capture screen, assert content
- `teardown()` — any extra cleanup (files, directories); ESN is stopped
  automatically by `run_case` after teardown

`run_case CASE_ID CASE_DESC` at the bottom of each file drives the full
lifecycle and accumulates pass/fail counts.

## API reference

### Lifecycle

| Function                  | Description                                            |
|---------------------------|--------------------------------------------------------|
| `make_fixture_dir FILE…`  | Temp dir seeded with named files from `fixtures/`      |
| `app_reset [COLS [ROWS]]` | Stop and restart ESN (default 80×25, in `APP_WORKDIR`) |
| `app_resize COLS ROWS`    | Resize the tmux window at runtime                      |

`make_fixture_dir` exports `APP_WORKDIR` so the next `app_reset`
launches ESN there. The directory is removed automatically after
the case finishes.

### Sending input

| Function                   | Description                                   |
|----------------------------|-----------------------------------------------|
| `send_key  [DELAY] [KEY…]` | Send named keys; wait DELAY; invalidate cache |
| `send_text [DELAY] TEXT`   | Type literal characters of TEXT               |
| `close_dialog TEXT`        | Close a dialog with Escape (see below)        |
| `try_keys KEY…`            | Fire-and-forget; suppresses errors (teardown) |

`DELAY` is one of `settle` (50 ms, default), `open` (150 ms),
`fileop` (300 ms), `resize` (400 ms).

Key tokens: named keys (`return`, `escape`, `tab`, `shift+tab`,
`up`, `down`, `left`, `right`, `home`, `end`, `pageup`, `pagedown`,
`backspace`, `delete`, `space`, `insert`, `f1`–`f10`), modifier
combos (`ctrl+x`, `ctrl+pgup`, `ctrl+pgdn`, `alt+x`, `alt+f1`–
`alt+f10`, `shift+f1`–`shift+f10`), or any single printable
character. Use `send_text` to type a multi-character string into
an in-app input (search box, inline rename).

**Closing dialogs with Escape.** Always use `close_dialog TEXT`
instead of `send_key escape` when dismissing a dialog. TEXT is the
dialog's identifying string (e.g. `"System information"`,
`"Mask"`) — the function sends Escape and polls until that text
leaves the screen. Use bare `send_key escape` only when the intent
is to trigger the Exit dialog on the main panel.

**Adding a new key token.** Most tokens map to a tmux key name
(`F6`, `Up`, `C-v`) or a plain escape sequence (`\e[5~` for PgUp)
and are sent through `tmux send-keys`. Tokens whose bytes must
arrive in one PTY write — `escape`, `insert`, `alt+f1`–`alt+f10` —
go through `tmux send-keys -H` from `send_key` directly, because
FPC's escape-sequence timer would otherwise split them and report a
different code. Confirm the bytes you choose reach FPC as the
intended `rKey` value by compiling a small probe against the
`Keyboard` unit and feeding the bytes via `tmux send-keys -H`.
Notably, xterm modifier sequences (`\e[17;3~` for Alt+F6) silently
degrade to plain F-keys; the ESC-prefix form (`\e\e[17~`) is what
produces `rawCode=_AltF6`.

### Screen access

| Function                | Description                                   |
|-------------------------|-----------------------------------------------|
| `screen_text`           | Full terminal text (plain, lazy-cached)       |
| `screen_ansi`           | Full terminal text with ANSI color codes      |
| `rect_text ROW COL H W` | Plain text from rectangle (1-based)           |
| `rect_bg ROW COL H W`   | Background color grid for rectangle           |
| `rect_fg ROW COL H W`   | Foreground color grid for rectangle           |
| `capture_info_line`     | Plain text of info line 1 (row 21, cols 2–40) |

### Assertions

| Function                                              | Description                                   |
|-------------------------------------------------------|-----------------------------------------------|
| `assert_text_present  ID TEXT [DESC]`                 | Fail if TEXT not found anywhere on screen     |
| `assert_text_absent   ID TEXT [DESC]`                 | Fail if TEXT found on screen                  |
| `assert_info_line     ID PREFIX [DESC]`               | Fail if info line 1 doesn't start with PREFIX |
| `assert_rect_bg       ID ROW COL H W COLOR [DESC]`    | Fail if any cell in rect has wrong bg         |
| `assert_rect_fg       ID ROW COL H W COLOR [DESC]`    | Fail if any cell in rect has wrong fg         |
| `assert_rect_text     ID ROW COL H W EXPECTED [DESC]` | Fail if rect text ≠ EXPECTED                  |
| `assert_rect_contains ID ROW COL H W TEXT [DESC]`     | Fail if TEXT not in rect                      |

### Logging

| Function              | Description                        |
|-----------------------|------------------------------------|
| `step N DESC`         | Print a step header                |
| `log_pass ID DESC`    | Record a passing assertion         |
| `log_fail ID DESC`    | Record a failing assertion         |
| `log_info MSG`        | Print an informational message     |
| `log_skip ID DESC`    | Record a skipped assertion         |

## Result structure

Each run creates a timestamped directory under `testing/results/`:

```
testing/results/YYYY-MM-DD_HH-MM/
  T016_02_basic_type.txt      — screen dump on failure (with --dump)
  T016_03_trdos3_indicator.txt
  …
```

The runner exits with code 0 if all assertions pass, 1 if any fail.

## Writing a new test case

```bash
#!/usr/bin/env bash
# TXXX — short description
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="TXXX"
CASE_DESC="Short description"

setup() {
  app_reset          # or: app_reset 120 30 for a wide terminal
  send_key           # settle after startup
}

run() {
  step 1 "Description of what this step checks"
  send_key down
  assert_text_present "${CASE_ID}_01_something" "expected text" \
    "Human-readable description of the assertion"
}

teardown() {
  try_keys ctrl+pageup   # soft cleanup; errors suppressed
}

run_case "$CASE_ID" "$CASE_DESC"
```

Name the file `TXXX_short_slug.sh`. The runner discovers all `T*.sh`
files under `cases/` automatically.
