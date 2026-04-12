#!/usr/bin/env bash
# lib/timing.sh — Single source of truth for all sleep durations (tmux mode).
#
# All waits in the test suite are expressed as named functions here.
# No numeric sleep literal may appear in any other file.
#
# Sourced by lib/common.sh before anything else.

[[ -n "${_TIMING_LOADED:-}" ]] && return 0
_TIMING_LOADED=1

# After launching the app; waits for first frame.
sleep_for_app_start() { sleep "${ESN_TEST_APP_START_DELAY:-0.5}"; }

# After sending the quit keystroke.
sleep_for_app_stop() { sleep 0.15; }

# After focus, pkill, window open, or general navigation.
sleep_for_settle() { sleep 0.05; }

# After terminal resize; waits for OnResize to fire.
sleep_for_resize() { sleep 0.4; }

# After pressing Enter to enter a ZX format panel (TRD/TAP/SCL/…).
sleep_for_open() { sleep 0.15; }

# After a file operation (copy, delete) completes.
sleep_for_file_op() { sleep 0.3; }
