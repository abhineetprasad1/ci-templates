#!/usr/bin/env bash
# ============================================================
# return-license.sh
# Returns a Unity Professional/Plus seat so it can be reused.
# In CI, prefer game-ci/unity-return-license GitHub Action.
#
# Usage:
#   UNITY_SERIAL=XX-XXXX-XXXX-XXXX-XXXX-XXXX \
#   UNITY_EMAIL=you@example.com \
#   UNITY_PASSWORD=secret \
#   ./scripts/return-license.sh /path/to/Unity
# ============================================================

set -euo pipefail

UNITY_BIN="${1:-/Applications/Unity/Hub/Editor/$(ls /Applications/Unity/Hub/Editor | tail -1)/Unity.app/Contents/MacOS/Unity}"

if [[ ! -x "$UNITY_BIN" ]]; then
  echo "WARNING: Unity binary not found, skipping license return." >&2
  exit 0
fi

# Personal licenses cannot be returned — skip gracefully
if [[ -z "${UNITY_SERIAL:-}" ]]; then
  echo "No UNITY_SERIAL set — skipping license return (Personal license or not needed)."
  exit 0
fi

"$UNITY_BIN" \
  -batchmode -nographics -quit \
  -returnlicense \
  -serial   "${UNITY_SERIAL}" \
  -username "${UNITY_EMAIL:?UNITY_EMAIL required}" \
  -password "${UNITY_PASSWORD:?UNITY_PASSWORD required}" \
|| echo "WARNING: License return exited non-zero (may already be returned)."

echo "Unity license returned."
