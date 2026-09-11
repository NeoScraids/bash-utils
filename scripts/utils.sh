#!/usr/bin/env bash
# ==============================================================================
# utils.sh
# Shared functions and constants for bash-utils automation suite.
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

# Header banner
banner() {
  echo -e "${CYAN}${BOLD}====================================================${RESET}"
  echo -e "${CYAN}${BOLD}         BASH-UTILS // DevOps Automation Suite       ${RESET}"
  echo -e "${CYAN}${BOLD}====================================================${RESET}"
}

# Structured logging with timestamp and level
log() {
  local level="$1"
  local message="$2"
  local color

  case "$level" in
    ERROR)   color="$RED" ;;
    WARN)    color="$YELLOW" ;;
    INFO)    color="$BLUE" ;;
    SUCCESS) color="$GREEN" ;;
    *)       color="$RESET" ;;
  esac

  echo -e "${BOLD}$(date +'%Y-%m-%d %H:%M:%S')${RESET} [${color}${level}${RESET}] ${message}"
}

# Verify required command availability
require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log "ERROR" "Missing required command: $cmd"
    return 1
  fi
  return 0
}