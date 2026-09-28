#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GROUP_SIZE="${LIMITBAR_TEST_GROUP_SIZE:-12}"
SUITE_TIMEOUT="${LIMITBAR_TEST_SUITE_TIMEOUT:-180}"
RETRY_NON_TIMEOUT_FAILURES="${LIMITBAR_TEST_RETRY_NON_TIMEOUT_FAILURES:-1}"

cd "${ROOT_DIR}"

source "${ROOT_DIR}/Scripts/test_environment.sh"

ARGS=(
  --group-size "${GROUP_SIZE}"
  --timeout "${SUITE_TIMEOUT}"
)

case "${RETRY_NON_TIMEOUT_FAILURES}" in
  0) ARGS+=(--no-retry-non-timeout-failures) ;;
  1) ;;
  *)
    echo "LIMITBAR_TEST_RETRY_NON_TIMEOUT_FAILURES must be 0 or 1" >&2
    exit 2
    ;;
esac

if [[ -n "${LIMITBAR_TEST_SHARD_INDEX:-}" || -n "${LIMITBAR_TEST_SHARD_COUNT:-}" ]]; then
  ARGS+=(
    --shard-index "${LIMITBAR_TEST_SHARD_INDEX:?LIMITBAR_TEST_SHARD_COUNT requires LIMITBAR_TEST_SHARD_INDEX}"
    --shard-count "${LIMITBAR_TEST_SHARD_COUNT:?LIMITBAR_TEST_SHARD_INDEX requires LIMITBAR_TEST_SHARD_COUNT}"
  )
fi

exec python3 "${ROOT_DIR}/Scripts/ci_swift_test_by_suite.py" "${ARGS[@]}" "$@"
