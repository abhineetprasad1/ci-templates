#!/usr/bin/env bash
# ============================================================
# activate-license.sh
# Helper for manual/self-hosted license debugging.
# In CI, prefer the game-ci/unity-activate GitHub Action.
#
# Usage:
#   UNITY_SERIAL=XX-XXXX-XXXX-XXXX-XXXX-XXXX \
#   UNITY_EMAIL=you@example.com \
#   UNITY_PASSWORD=secret \
#   ./scripts/activate-license.sh /path/to/Unity
# ============================================================

set -euo pipefail

UNITY_BIN="${1:-/Applications/Unity/Hub/Editor/$(ls /Applications/Unity/Hub/Editor | tail -1)/Unity.app/Contents/MacOS/Unity}"

if [[ ! -x "$UNITY_BIN" ]]; then
  echo "ERROR: Unity binary not found at: $UNITY_BIN" >&2
  exit 1
fi

if [[ -n "${UNITY_LICENSE:-}" ]]; then
  # Write .ulf file from env var (base64 or raw XML)
  LICENSE_FILE="/tmp/unity.ulf"
  if echo "$UNITY_LICENSE" | base64 --decode > "$LICENSE_FILE" 2>/dev/null; then
    echo "Decoded base64 Unity license to $LICENSE_FILE"
  else
    echo "$UNITY_LICENSE" > "$LICENSE_FILE"
    echo "Wrote raw Unity license to $LICENSE_FILE"
  fi
  "$UNITY_BIN" -batchmode -nographics -manualLicenseFile "$LICENSE_FILE" -quit || true
elif [[ -n "${UNITY_SERIAL:-}" ]]; then
  "$UNITY_BIN" \
    -batchmode -nographics -quit \
    -serial   "${UNITY_SERIAL}" \
    -username "${UNITY_EMAIL:?UNITY_EMAIL required}" \
    -password "${UNITY_PASSWORD:?UNITY_PASSWORD required}"
else
  echo "ERROR: Set UNITY_LICENSE or UNITY_SERIAL + UNITY_EMAIL + UNITY_PASSWORD" >&2
  exit 1
fi

echo "Unity license activated."
