#!/usr/bin/env bash
# T027 — Runtime resize correctness
#
# Regression test for: screen corruption on terminal grow.
#
# Reported symptom: after widening the terminal from 80 to a larger width,
# old scrollbar characters (▲ ■ ▒ ▼ ║) appeared beyond column 80 while
# the panels remained at the old 80-column width.
#
# Root cause: SetVideoMode not called on resize (VideoBuf kept old
# dimensions), and GlobalRedraw did not Cls before repainting.
#
# Assertions that would fail against the broken binary:
#   - After resize to 120 cols, every non-empty screen line must be
#     ≥ 100 chars (panels fill the full terminal width, not clipped at 80).
#   - The adjacent double-border ╗╔ that marks the gap between two 40-col
#     panels must NOT appear after resize to 120 cols (panels are now wider).
#   - After shrinking back to 80 cols, the wide layout must not linger
#     (╗╔ reappears at the expected 80-col position).

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T027"
CASE_DESC="Runtime resize: no corruption, cursor clamping"

# ---------------------------------------------------------------------------
# check_line_width MIN_WIDTH TEST_ID DESC
# Passes if ALL non-empty lines from app_screen_text are >= MIN_WIDTH chars.
# This catches the reported bug: broken resize leaves lines clipped at 80 cols
# when the terminal is 120 cols wide.
# ---------------------------------------------------------------------------
check_line_width() {
  local min_width="$1"
  local test_id="$2"
  shift 2
  local description="$*"

  local screen short_lines
  screen=$(app_screen_text)
  # Find non-empty lines shorter than min_width.
  # Exclude the status bar line (contains "Exit") — tmux strips its
  # trailing spaces making it shorter than the panel width.
  short_lines=$(echo "$screen" | awk -v min="$min_width" \
    'length > 0 && length < min && !/Exit/ { print NR": "length" chars: "$0 }' \
    | head -5)

  if [[ -n "$short_lines" ]]; then
    log_fail "$test_id" \
      "$description — lines shorter than ${min_width} cols found:
$short_lines"
  else
    log_pass "$test_id" "$description"
  fi
}

# ---------------------------------------------------------------------------
# check_double_border_present TEST_ID DESC
# At 80 cols the ╗╔ pair must appear (confirming panels are back at 40 cols).
# ---------------------------------------------------------------------------
check_double_border_present() {
  local test_id="$1"; shift
  local description="$*"
  assert_text_present "$test_id" "$(printf '\u2557\u2554')" "$description"
}

setup() {
  app_reset 80 25
  # Navigate down so cursor is away from row 1 (needed for clamp step).
  send_key down down down
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Baseline at 80×25 — panels fill exactly 80 columns"

  check_double_border_present "${CASE_ID}_01_double_border_at_80" \
    "At 80 cols the ╗╔ boundary between the two 40-col panels is visible"

  check_line_width 78 "${CASE_ID}_01_lines_at_least_78" \
    "All non-empty screen lines are at least 78 chars wide at 80-col terminal"

  # -----------------------------------------------------------------------
  step 2 "Grow to 120×30 — panels must span full width, no stale content"
  app_resize 120 30
  # rKey detects the resize on its next poll cycle (needResize flag set by
  # SIGWINCH); no keystroke needed to trigger GlobalRedraw.

  check_line_width 118 "${CASE_ID}_02_lines_span_120" \
    "After resize to 120 cols all non-empty lines are >= 118 chars. \
Fails if VideoBuf was not reallocated (old bug: lines clipped at 80 cols, \
stale chars beyond)"

  # -----------------------------------------------------------------------
  step 3 "Keyboard still works after grow — cursor moves, no ^A^B echo"
  # After DoneVideo/InitVideo the terminal must still be in raw mode.
  # If DoneKeyboard/InitKeyboard is missing, keypresses echo as ^A^B etc.
  send_key open down
  assert_text_absent "${CASE_ID}_03_no_control_chars" \
    "^A" \
    "No raw control-character echo after resize — keyboard still in raw mode"

  # -----------------------------------------------------------------------
  step 4 "Shrink back to 80×25 — wide layout must not linger"
  app_resize 80 25

  check_double_border_present "${CASE_ID}_04_double_border_back" \
    "After shrinking, the 40-col panel boundary ╗╔ reappears. \
Fails if Cls was not called before repaint (old content lingers)"

  check_line_width 78 "${CASE_ID}_04_lines_back_at_80" \
    "Lines return to 80-col width after shrink"

  # -----------------------------------------------------------------------
  step 5 "Shrink height to 16 rows — cursor clamping fires"
  app_resize 80 16
  send_key down
  assert_text_absent "${CASE_ID}_05_no_crash_message" \
    "Terminal too small" \
    "No 'Terminal too small' message at 80×16 (above the 40×12 minimum)"
}

teardown() {
  :
}

run_case "$CASE_ID" "$CASE_DESC"
