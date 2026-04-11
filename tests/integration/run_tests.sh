#!/usr/bin/env bash
# run_tests.sh — Master test runner for ESN end-to-end tests.
#
# Usage:
#   ./run_tests.sh [--attached] [--case=T0xx] [--dump] [--stop-on-failure]
#                  [--verbose]
#
# Options:
#   --attached         Open a terminal window to observe the tmux session
#   --case=T004        Run only the named test case (prefix match)
#   --dump             Write screen dumps to OUT_DIR on assertion failure
#   --stop-on-failure  Stop after the first failing test case
#   --verbose          Print extra diagnostic output

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------

CASE_FILTER=""
VERBOSE=0
STOP_ON_FAILURE=0
export ATTACHED=0
export DUMP=0

for arg in "$@"; do
  case "$arg" in
    --case=*)          CASE_FILTER="${arg#--case=}" ;;
    --attached)        ATTACHED=1 ;;
    --dump)            DUMP=1 ;;
    --stop-on-failure) STOP_ON_FAILURE=1 ;;
    --verbose)         VERBOSE=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Create output directory
# ---------------------------------------------------------------------------

RUN_TIMESTAMP="$(date '+%Y-%m-%d_%H-%M')"
export OUT_DIR="$SCRIPT_DIR/results/$RUN_TIMESTAMP"
[[ "$DUMP" == "1" ]] && mkdir -p "$OUT_DIR"

echo "ESN end-to-end tests — $(date '+%Y-%m-%d %H:%M:%S')"
[[ "$ATTACHED" == "1" ]] && echo "Mode: attached (Terminal.app window will open)"
[[ "$DUMP"     == "1" ]] && echo "Output directory: $OUT_DIR"

# ---------------------------------------------------------------------------
# Run cases
# ---------------------------------------------------------------------------

overall=0

case_scripts=()
while IFS= read -r -d '' f; do
  case_scripts+=("$f")
done < <(find "$SCRIPT_DIR/cases" -name 'T*.sh' -print0 | sort -z)

for case_script in "${case_scripts[@]}"; do
  case_base="$(basename "$case_script" .sh)"

  if [[ -n "$CASE_FILTER" ]] && [[ "$case_base" != "${CASE_FILTER}"* ]]; then
    continue
  fi

  [[ $VERBOSE -eq 1 ]] && echo "  Running: $case_script"

  (
    _runner_dir="$SCRIPT_DIR"
    source "$_runner_dir/lib/common.sh"
    source "$_runner_dir/lib/app.sh"
    source "$case_script"
  ) || { overall=1; [[ $STOP_ON_FAILURE -eq 1 ]] && break; }
done

echo ""
[[ "$DUMP" == "1" ]] && echo "Results written to: $OUT_DIR"
exit $overall
