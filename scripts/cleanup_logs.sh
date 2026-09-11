#!/usr/bin/env bash
# ==============================================================================
# cleanup_logs.sh
# Rotates and purges log files older than a specified threshold.
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

usage() {
  cat <<EOF
Usage: $0 --dir <log_directory> [--days <retention_days>]

Options:
  --dir    Directory path containing logs to inspect (Required)
  --days   Files older than this amount of days will be deleted (Default: 30)
  --help   Show this help message
EOF
  exit 1
}

days=30
log_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      log_dir="${2:-}"
      shift 2
      ;;
    --days)
      days="${2:-30}"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    *)
      log "ERROR" "Unknown option: $1"
      usage
      ;;
  esac
done

if [[ -z "$log_dir" ]]; then
  log "ERROR" "--dir parameter is required."
  usage
fi

banner
log "INFO" "Starting log retention purge in: $log_dir (Retention threshold: >${days} days)"

if [[ ! -d "$log_dir" ]]; then
  log "ERROR" "Directory does not exist: $log_dir"
  exit 2
fi

deleted_count=0
while IFS= read -r -d '' file; do
  log "INFO" "Purging expired log: $file"
  rm -f "$file"
  deleted_count=$((deleted_count + 1))
done < <(find "$log_dir" -type f -mtime +"$days" -print0)

log "SUCCESS" "Cleanup completed. Total files removed: $deleted_count."
exit 0