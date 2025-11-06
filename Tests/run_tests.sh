#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
EXECUTABLE="${BUILD_DIR}/LifecycleSafetyTests"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

xcrun clang \
  -g \
  -fmodules \
  -fobjc-arc \
  -DDEBUG=0 \
  -I"${PROJECT_ROOT}" \
  -isysroot "${SDK_PATH}" \
  -F"${SDK_PATH}/System/Library/Frameworks" \
  -framework Foundation \
  "${PROJECT_ROOT}/AWMSafeDispatchTimer.m" \
  "${SCRIPT_DIR}/LifecycleSafetyTests.m" \
  "${SCRIPT_DIR}/main.m" \
  -o "${EXECUTABLE}"

chmod +x "${EXECUTABLE}"

"${EXECUTABLE}"
