#!/usr/bin/env bash
# T044 — Unicode filenames preserve panel column separators
#
# Cells in a PC panel are tracked by display width (cells), not by
# UTF-16 codeunit count or UTF-8 byte count.  A miscount on any
# entry — Cyrillic (1 cell, 2 bytes), CJK (2 cells, 3 bytes),
# astral emoji (2 cells, surrogate pair), regional-indicator flag
# (single cluster, 2 cells, two surrogate pairs), ZWJ family
# (single cluster, 2 cells, multiple codepoints), skin-tone-modified
# emoji (single cluster, 2 cells, base + modifier) — would either
# clobber the next column's content or push the column-1/2 and
# column-2/3 separators ('│' at columns 14 and 27 of the left
# panel) off their grid.
#
# This test is the integration anchor for the F2 / F7 / P3 / P5
# fixes that ensure CMPrint stores grapheme clusters as single
# cells, the Windows console marks East-Asian Wide cells with
# COMMON_LVB_LEADING_BYTE, and ExtendedGraphemeClusterDisplayWidth
# recognises regional-indicator pairs as 2 cells.
#
# Why the test exists: the vendored FPC RTL slice (lib/fpc/) holds
# a `{ todo: handle emoji + modifiers }` flag in the upstream width
# function.  When upstream resolves it, ESN will refresh the slice
# and drop the local P5 patch.  This case must keep passing across
# that refresh, otherwise we silently regress to the user-visible
# "extension shifted right; column separator broken" symptom.
#
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T044"
CASE_DESC="Unicode filenames preserve panel column separators"

setup() {
  # Build an ad-hoc fixture directory.  run_case will rm -rf it.
  _FIXTURE_DIR="$(mktemp -d)"
  local d="$_FIXTURE_DIR"
  # One file per grapheme/width category that the rendering
  # pipeline must handle.  Each name has a non-ASCII prefix so the
  # entry width measurement runs through the cluster code path.
  touch \
    "$d/файл-cyrillic.txt"        `# Cyrillic: 1-cell, 2-byte UTF-8` \
    "$d/中文-cjk.txt"             `# CJK: 2-cell, 3-byte UTF-8` \
    "$d/café-latin1.txt"          `# Latin-1: composed e+acute (1 cell)` \
    "$d/star-★-bmp-emoji.txt"     `# BMP symbol emoji: 1 cell` \
    "$d/smile-😀-astral.txt"      `# Astral emoji: surrogate pair, 2 cells` \
    "$d/family-👨‍👩‍👧-zwj.txt"   `# ZWJ sequence: 1 cluster, 2 cells` \
    "$d/usa-🇺🇸-flag.txt"         `# Regional-indicator pair: 2 cells (P5)` \
    "$d/wave-👋🏽-skin.txt"        `# Skin-tone modifier: 1 cluster, 2 cells` \
    "$d/long-中中中中中中中中.txt" `# CJK truncation budget overflow`
  export APP_WORKDIR="$d"
  app_reset
  send_key
}

run() {
  # ---------------------------------------------------------------------
  step 1 "Each Unicode category lands in the panel"
  # Substring presence: the cluster reaches the cell buffer.
  # Layout integrity is checked in step 2.
  assert_text_present "${CASE_ID}_01_cyrillic" "файл" \
    "Cyrillic filename visible"
  assert_text_present "${CASE_ID}_01_cjk" "中文" \
    "CJK filename visible"
  assert_text_present "${CASE_ID}_01_latin1" "café" \
    "Latin-1 diacritic filename visible"
  assert_text_present "${CASE_ID}_01_bmp_emoji" "★" \
    "BMP-symbol emoji visible"
  assert_text_present "${CASE_ID}_01_astral" "😀" \
    "Astral-plane emoji visible"
  assert_text_present "${CASE_ID}_01_flag" "🇺🇸" \
    "Regional-indicator flag visible"
  assert_text_present "${CASE_ID}_01_skin_tone" "👋🏽" \
    "Skin-tone-modifier emoji visible"

  # ---------------------------------------------------------------------
  step 2 "Column separators '│' intact on every entry row (3-column mode)"
  # ESN starts with both panels in 3-column mode (Columns=3).  pcInfo
  # draws '│' at posX + cw and posX + 2*cw on every entry row, where
  # cw = (PanelW + 1) div 3 = 13 for the default 38-wide panel.
  # pcPDF then writes 12-cell entries into each sub-column.  If the
  # entry's display-width measurement under-counts a grapheme cluster
  # (e.g. RIS pair → 1 cell instead of 2; CJK + skin-tone modifier;
  # ZWJ family), the entry overflows its 12-cell sub-column and
  # clobbers the next '│' separator.
  #
  # The test counts '│' occurrences per row.  Every entry row should
  # have exactly four: two in the left panel (between sub-columns 1/2
  # and 2/3) and two in the right panel (same).  A miscounted cluster
  # drops the count to three.
  #
  # Counting tolerates wide-char content (each cluster is a single
  # character in the captured line regardless of cell width), so the
  # assertion stays meaningful when filenames span CJK or astral-plane
  # codepoints.
  local screen
  screen=$(screen_text)
  local row bad_rows=""
  for row in 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19; do
    local line count
    line=$(printf '%s\n' "$screen" | sed -n "${row}p")
    # Bash $'…' decodes the U+2502 (│) escape so grep -o sees the
    # right byte sequence.
    count=$(printf '%s' "$line" \
      | grep -o $'\xe2\x94\x82' | wc -l | tr -d ' ')
    if [[ "$count" != "4" ]]; then
      bad_rows="$bad_rows row$row($count)"
    fi
  done

  if [[ -z "$bad_rows" ]]; then
    log_pass "${CASE_ID}_02_sep_count" \
      "Every entry row has 4 '│' separators (2 per panel)"
  else
    log_fail "${CASE_ID}_02_sep_count" \
      "Wrong '│' count on:$bad_rows (expected 4 per row)"
  fi
  _maybe_dump "${CASE_ID}_02_sep_count"
}

teardown() { :; }

run_case "$CASE_ID" "$CASE_DESC"
