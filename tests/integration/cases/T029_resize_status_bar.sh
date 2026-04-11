#!/usr/bin/env bash
# T029 — Status bar survives terminal resize
#
# Regression test for: the bottom F-key status bar disappears after a
# terminal resize because GlobalRedraw (called from OnResize) calls Cls
# but does not redraw the status bar.  The bar only reappears on the
# next key press, when the navigation loop re-renders it.

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CASE_ID="T029"
CASE_DESC="Status bar persists after resize"

setup() {
  app_reset 80 25
}

run() {
  # -----------------------------------------------------------------------
  step 1 "Baseline — status bar visible at 80×25"
  assert_text_present "${CASE_ID}_01_exit_label" \
    "Exit" \
    "Status bar shows 'Exit' label at 80×25"

  # -----------------------------------------------------------------------
  step 2 "Grow to 120×30 — status bar must still be present"
  app_resize 120 30
  assert_text_present "${CASE_ID}_02_exit_after_grow" \
    "Exit" \
    "Status bar shows 'Exit' after resize to 120×30. \
Fails if GlobalRedraw cleared the bar without redrawing it"

  # -----------------------------------------------------------------------
  step 3 "Shrink back to 80×25 — status bar must still be present"
  app_resize 80 25
  assert_text_present "${CASE_ID}_03_exit_after_shrink" \
    "Exit" \
    "Status bar shows 'Exit' after shrink back to 80×25"
}

teardown() {
  :
}

run_case "$CASE_ID" "$CASE_DESC"
