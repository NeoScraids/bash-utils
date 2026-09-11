#!/usr/bin/env bash
# ==============================================================================
# deploy_app.sh
# Automates application deployment and service restart on a remote host via SSH.
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

usage() {
  cat <<EOF
Usage: $0 --repo <git_url> --service <systemd_service_name> --host <user@host> [--branch <branch_name>]

Options:
  --repo     Git repository clone URL (Required)
  --service  Systemd service identifier to restart (Required)
  --host     Remote SSH target host formatted as user@hostname (Required)
  --branch   Target Git branch (Default: main)
  --help     Show this help message
EOF
  exit 1
}

repo=""
svc=""
host=""
branch="main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --service)
      svc="${2:-}"
      shift 2
      ;;
    --host)
      host="${2:-}"
      shift 2
      ;;
    --branch)
      branch="${2:-main}"
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

if [[ -z "$repo" || -z "$svc" || -z "$host" ]]; then
  log "ERROR" "Parameters --repo, --service and --host are mandatory."
  usage
fi

require_command "ssh" || exit 2

banner
log "INFO" "Initiating remote deployment for '$svc' on host '$host' (branch: $branch)..."

ssh -o BatchMode=yes -o ConnectTimeout=10 "$host" bash <<REMOTE_SCRIPT
  set -euo pipefail
  TARGET_DIR="/opt/$svc"

  echo "==> Preparing target directory: \$TARGET_DIR"
  if [[ ! -d "\$TARGET_DIR/.git" ]]; then
    echo "==> Fresh clone from $repo..."
    sudo git clone -b "$branch" "$repo" "\$TARGET_DIR"
  else
    echo "==> Pulling latest changes from branch $branch..."
    cd "\$TARGET_DIR"
    sudo git fetch origin "$branch"
    sudo git checkout "$branch"
    sudo git pull origin "$branch"
  fi

  echo "==> Restarting systemd service: $svc..."
  sudo systemctl restart "$svc"
  sudo systemctl is-active --quiet "$svc" && echo "==> Service $svc is active and healthy."
REMOTE_SCRIPT

log "SUCCESS" "Deployment of '$svc' completed successfully on host '$host'."
exit 0