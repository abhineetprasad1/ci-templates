#!/usr/bin/env bash
# ============================================================
# build-number.sh
# Outputs BUILD_NUMBER and BUILD_VERSION to GITHUB_OUTPUT.
# Safe to source directly or run as a step.
#
# Priority:
#   1. Exact git tag on HEAD     → version = tag, build = run_number
#   2. No tag                    → version = 0.1.0, build = run_number
# ============================================================

set -euo pipefail

BUILD_NUMBER="${GITHUB_RUN_NUMBER:-0}"

if TAG=$(git describe --tags --exact-match HEAD 2>/dev/null); then
  # Strip leading 'v' — v1.2.3 → 1.2.3
  BUILD_VERSION="${TAG#v}"
  echo "Detected release tag: ${TAG} → version ${BUILD_VERSION}"
else
  BUILD_VERSION="0.1.0"
  echo "No exact tag on HEAD, using fallback version ${BUILD_VERSION}"
fi

echo "Build number : ${BUILD_NUMBER}"
echo "Build version: ${BUILD_VERSION}"

# Write to GITHUB_OUTPUT if running inside Actions
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "build_number=${BUILD_NUMBER}"  >> "$GITHUB_OUTPUT"
  echo "build_version=${BUILD_VERSION}" >> "$GITHUB_OUTPUT"
fi

# Also export for any subsequent shell steps in the same job
export BUILD_NUMBER
export BUILD_VERSION
