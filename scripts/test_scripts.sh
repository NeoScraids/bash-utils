#!/usr/bin/env bash
# ==============================================================================
# test_scripts.sh
# Unit and integration test runner for the bash-utils automation suite.
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

FAILED=0
PASSED=0

assert_success() {
  local desc="$1"
  shift
  if "$@"; then
    log "SUCCESS" "PASS: $desc"
    PASSED=$((PASSED + 1))
  else
    log "ERROR" "FAIL: $desc"
    FAILED=$((FAILED + 1))
  fi
}

assert_exit_code() {
  local expected_code="$1"
  local desc="$2"
  shift 2

  set +e
  "$@" >/dev/null 2>&1
  local code=$?
  set -e

  if [[ "$code" -eq "$expected_code" ]]; then
    log "SUCCESS" "PASS: $desc (exit code $code)"
    PASSED=$((PASSED + 1))
  else
    log "ERROR" "FAIL: $desc (expected $expected_code, got $code)"
    FAILED=$((FAILED + 1))
  fi
}

banner
log "INFO" "Executing automated test suite for bash-utils..."

# Test 1: Syntax check with bash -n
for script in "${SCRIPT_DIR}"/*.sh; do
  assert_success "Syntax check: $(basename "$script")" bash -n "$script"
done

# Test 2: Help flag exit codes
assert_exit_code 1 "backup.sh --help displays usage" bash "${SCRIPT_DIR}/backup.sh" --help
assert_exit_code 1 "cleanup_logs.sh --help displays usage" bash "${SCRIPT_DIR}/cleanup_logs.sh" --help
assert_exit_code 1 "deploy_app.sh --help displays usage" bash "${SCRIPT_DIR}/deploy_app.sh" --help
assert_exit_code 1 "monitor.sh --help displays usage" bash "${SCRIPT_DIR}/monitor.sh" --help

# Test 3: Validation on missing required arguments
assert_exit_code 1 "backup.sh fails on missing args" bash "${SCRIPT_DIR}/backup.sh"
assert_exit_code 1 "cleanup_logs.sh fails on missing args" bash "${SCRIPT_DIR}/cleanup_logs.sh"
assert_exit_code 1 "deploy_app.sh fails on missing args" bash "${SCRIPT_DIR}/deploy_app.sh"

# Test 4: Directory validation
assert_exit_code 2 "backup.sh returns 2 on invalid dir" bash "${SCRIPT_DIR}/backup.sh" --source "/nonexistent_path_xyz_123" --dest "ftp://test"
assert_exit_code 2 "cleanup_logs.sh returns 2 on invalid dir" bash "${SCRIPT_DIR}/cleanup_logs.sh" --dir "/nonexistent_path_xyz_123"

# Summary
echo ""
log "INFO" "===================================================="
log "INFO" "Test Results Summary:"
log "SUCCESS" "Total Passed: $PASSED"
if [[ "$FAILED" -gt 0 ]]; then
  log "ERROR" "Total Failed: $FAILED"
  exit 1
else
  log "SUCCESS" "All tests completed successfully with zero regressions."
  exit 0
fi
