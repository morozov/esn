#!/usr/bin/env bash
# T031 — Panel column separators align header-to-entry at wide terminal
#
# Regression: at terminal widths >80 the column separator │ in entry rows
# was drawn at a hardcoded column (PosX+13) while Build() Part '1' placed
# it at PosX+cw (cw=(PanelW+1) div 3).  The two positions coincided only
# at 80 columns (cw=13).  At 120 columns (cw=19) they diverged by 6
# columns, leaving the header row showing │ at a different x-position than
# file-entry rows.  The same bug existed in zx_render.zxPDF (TRD/TAP).
#
# Tests: spec/02-pc-panel.md — single-column layout
#        spec/03-trd-panel.md, spec/04-tap-panel.md — ZX single-column
#        spec/01-architecture.md — Build() Part '1' separator positions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T031"
CASE_DESC="Panel separator columns align header-to-entry at 120-wide"

_T031_W=120
_T031_H=25

setup() {
  make_fixture_dir sample.trd sample.tap
  app_reset "$_T031_W" "$_T031_H"
  send_key home
}

# Assert that separators on entry row 3 align with header row 2.
# $1 — step prefix for assertion IDs (e.g. "03")
# $2 — label for log messages (e.g. "PC", "TRD", "TAP")
# $3 — sep1 column
# $4 — sep2 column
# $5 — cw value (for the hardcoded-position guard)
_assert_separators() {
  local pfx="$1" label="$2" sep1="$3" sep2="$4" cw="$5"

  assert_rect_contains "${CASE_ID}_${pfx}_sep1_header" \
    2 "$sep1" 1 1 "│" \
    "$label: first separator │ at col $sep1 on header row"
  assert_rect_contains "${CASE_ID}_${pfx}_sep1_entry" \
    3 "$sep1" 1 1 "│" \
    "$label: first separator │ at col $sep1 on first entry row"
  assert_rect_contains "${CASE_ID}_${pfx}_sep2_header" \
    2 "$sep2" 1 1 "│" \
    "$label: second separator │ at col $sep2 on header row"
  assert_rect_contains "${CASE_ID}_${pfx}_sep2_entry" \
    3 "$sep2" 1 1 "│" \
    "$label: second separator │ at col $sep2 on first entry row"
  if [[ "$cw" -gt 13 ]]; then
    assert_rect_text "${CASE_ID}_${pfx}_no_sep_at_14" \
      3 14 1 1 " " \
      "$label: col 14 (old hardcoded position) is a space, not │"
  fi
}

run() {
  # Left panel: PosX=1, PanelW = GmaxX/2 - 2 = 58, cw = (58+1)/3 = 19.
  # Separator columns: PosX+cw=20 and PosX+2*cw=39.
  local panel_w=$(( _T031_W / 2 - 2 ))
  local cw=$(( (panel_w + 1) / 3 ))
  local sep1=$(( 1 + cw ))
  local sep2=$(( 1 + 2 * cw ))

  step 1 "PC: separators align between header and entry rows"
  _assert_separators "01" "PC" "$sep1" "$sep2" "$cw"

  # -- TRD panel ----------------------------------------------------------

  step 2 "Enter first ZX image at 120 columns"
  send_key down
  send_key open return

  step 3 "ZX panel 1: separators align between header and entry rows"
  _assert_separators "03" "ZX1" "$sep1" "$sep2" "$cw"

  exit_zx_panel

  # -- Second ZX panel ----------------------------------------------------

  step 4 "Enter second ZX image at 120 columns"
  send_key home
  send_key down down
  send_key open return

  step 5 "ZX panel 2: separators align between header and entry rows"
  _assert_separators "05" "ZX2" "$sep1" "$sep2" "$cw"

  exit_zx_panel
}

teardown() {
  :
}

run_case "$CASE_ID" "$CASE_DESC"
