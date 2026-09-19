#!/usr/bin/env bash
# ==============================================================================
# monitor.sh
# Periodic system resource telemetry collector with threshold alerting (CPU/MEM/DISK).
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

usage() {
  cat <<EOF
Usage: $0 [--interval <seconds>] [--threshold <cpu_percent>] [--mem-threshold <mem_percent>] [--slack-webhook <url>] [--iterations <count>]

Options:
  --interval       Sampling interval in seconds (Default: 60)
  --threshold      CPU threshold percentage to trigger alert (Default: 80)
  --mem-threshold  Memory usage percentage to trigger alert (Default: 90)
  --slack-webhook  Slack incoming webhook URL for alert dispatch
  --iterations     Number of iterations to run, 0 for infinite (Default: 0)
  --help           Show this help message
EOF
  exit 1
}

interval=60
cpu_threshold=80
mem_threshold=90
webhook=""
iterations=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval)
      interval="${2:-60}"
      shift 2
      ;;
    --threshold)
      cpu_threshold="${2:-80}"
      shift 2
      ;;
    --mem-threshold)
      mem_threshold="${2:-90}"
      shift 2
      ;;
    --slack-webhook)
      webhook="${2:-}"
      shift 2
      ;;
    --iterations)
      iterations="${2:-0}"
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

banner
log "INFO" "Starting system resource monitor (Interval: ${interval}s, CPU threshold: ${cpu_threshold}%, MEM threshold: ${mem_threshold}%)"

# Graceful termination handler
cleanup_trap() {
  log "INFO" "Monitoring process received termination signal. Exiting cleanly..."
  exit 0
}
trap cleanup_trap SIGINT SIGTERM

current_iter=0

while true; do
  # Telemetry extraction without requiring bc
  cpu_idle=$(top -bn1 | awk -F',' '/Cpu\(s\)/ {for(i=1;i<=NF;i++) if($i ~ /id/) {gsub(/[^0-9.]/,"",$i); print $i}}')
  if [[ -z "$cpu_idle" ]]; then
    # Fallback parsing for different top format implementations
    cpu_idle=$(top -bn1 | awk '/Cpu/ {for(i=1;i<=NF;i++) if($i ~ /id/) print $(i-1)}')
  fi

  cpu_usage=$(awk -v idle="${cpu_idle:-0}" 'BEGIN { printf "%.1f", (100 - idle) }')
  mem_info=$(free -m | awk '/Mem:/ {printf "%d/%d MB (%.1f%%)", $3, $2, ($3/$2)*100}')
  mem_pct=$(free -m | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}')
  disk_info=$(df -h / | awk 'NR==2 {printf "%s used of %s (%s)", $3, $2, $5}')

  status_line="CPU: ${cpu_usage}% | MEM: ${mem_info} | DISK: ${disk_info}"

  cpu_alert=$(awk -v usage="$cpu_usage" -v limit="$cpu_threshold" 'BEGIN { if (usage >= limit) print 1; else print 0 }')
  mem_alert=$(awk -v usage="${mem_pct:-0}" -v limit="$mem_threshold" 'BEGIN { if (usage >= limit) print 1; else print 0 }')

  if [[ "$cpu_alert" -eq 1 || "$mem_alert" -eq 1 ]]; then
    [[ "$cpu_alert" -eq 1 ]] && alert_reason="CPU at ${cpu_usage}%"
    [[ "$mem_alert" -eq 1 ]] && alert_reason="${alert_reason:+${alert_reason}, }MEM at ${mem_pct}%"
    log "WARN" "ALERT (${alert_reason}): ${status_line}"
    if [[ -n "$webhook" ]]; then
      require_command "curl" && \
        curl -sS -X POST -H 'Content-type: application/json' \
          --data "{\"text\":\"[ALERT] Host: $(hostname) - ${alert_reason} | ${status_line}\"}" \
          "$webhook" >/dev/null 2>&1 || true
    fi
  else
    log "INFO" "${status_line}"
  fi

  current_iter=$((current_iter + 1))
  if [[ "$iterations" -gt 0 && "$current_iter" -ge "$iterations" ]]; then
    log "SUCCESS" "Completed $iterations iterations. Finished monitoring."
    break
  fi

  sleep "$interval"
done

exit 0
