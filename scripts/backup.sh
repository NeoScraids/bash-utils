#!/usr/bin/env bash
# ==============================================================================
# backup.sh
# Directory backup orchestrator with compression, remote upload (S3/FTP) and cleanup.
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

usage() {
  cat <<EOF
Usage: $0 --source <dir> --dest <s3://...|ftp://...> [--retention <days>]

Options:
  --source     Path to directory to backup (Required)
  --dest       Remote destination URI: s3://bucket/path or ftp://user:pass@host/path (Required)
  --retention  Number of days for backup retention reference (Default: 7)
  --help       Show this help message
EOF
  exit 1
}

src=""
dest=""
retention=7

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      src="${2:-}"
      shift 2
      ;;
    --dest)
      dest="${2:-}"
      shift 2
      ;;
    --retention)
      retention="${2:-7}"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    *)
      log "ERROR" "Unknown argument: $1"
      usage
      ;;
  esac
done

if [[ -z "$src" || -z "$dest" ]]; then
  log "ERROR" "Parameters --source and --dest are mandatory."
  usage
fi

banner
log "INFO" "Starting backup process..."

if [[ ! -d "$src" ]]; then
  log "ERROR" "Source directory not found: $src"
  exit 2
fi

archive_name="$(basename "$src")-$(date +%F_%H%M%S).tar.gz"
archive_file="/tmp/${archive_name}"

log "INFO" "Compressing $src into $archive_file..."
tar -czf "$archive_file" -C "$(dirname "$src")" "$(basename "$src")"
log "SUCCESS" "Archive created successfully ($(du -h "$archive_file" | cut -f1))"

if [[ "$dest" == s3://* ]]; then
  require_command "aws" || exit 3
  log "INFO" "Uploading to AWS S3: $dest"
  aws s3 cp "$archive_file" "$dest"
  log "SUCCESS" "S3 upload complete."
else
  require_command "curl" || exit 3
  log "INFO" "Uploading via cURL/FTP: $dest"
  curl -sS -T "$archive_file" "$dest"
  log "SUCCESS" "Remote transfer complete."
fi

rm -f "$archive_file"
log "INFO" "Temporary local archive removed."
log "SUCCESS" "Backup procedure completed successfully. Retention policy: $retention days."
exit 0