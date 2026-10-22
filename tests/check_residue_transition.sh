#!/usr/bin/env bash
set -euo pipefail

review_log="$(mktemp)"
trap 'rm -f "$review_log"' EXIT

if ! godot --headless --path . --script tests/test_residue_transition.gd >"$review_log" 2>&1; then
	cat "$review_log"
	exit 1
fi
if rg -q 'SCRIPT ERROR|RESIDUE_TRANSITION_FAILED' "$review_log"; then
	cat "$review_log"
	exit 1
fi
if ! rg -q '^RESIDUE_TRANSITION_OK$' "$review_log"; then
	cat "$review_log"
	exit 1
fi

rg 'RESIDUE_TRANSITION_OK' "$review_log"
