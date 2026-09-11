<div align="center">

  <h1>bash-utils</h1>
  <p><strong>Production-Grade DevOps Automation & Systems Administration Toolkit</strong></p>

  <p>
    <img src="https://img.shields.io/badge/Language-GNU_Bash_5.0+-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white" alt="Bash" />
    <img src="https://img.shields.io/badge/Platform-Linux_%2F_POSIX-FCC624?style=flat-square&logo=linux&logoColor=black" alt="Linux" />
    <img src="https://img.shields.io/badge/Testing-Automated_Suite-0ea5e9?style=flat-square&logo=github-actions&logoColor=white" alt="Testing" />
    <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License" />
  </p>

</div>

---

### Overview

`bash-utils` is a modular collection of robust shell scripts engineered for Linux systems administration, cloud infrastructure maintenance, automated backups, and system telemetry.

Every utility adheres to strict production engineering guidelines:
- **Strict Error Handling:** Enforces `set -euo pipefail` and custom exit codes across all components.
- **Defensive Parameter Parsing:** Validates presence, types, and permissions before execution.
- **Standardized Structured Logging:** ISO 8601 timestamps with colored log levels (`INFO`, `WARN`, `ERROR`, `SUCCESS`).
- **Zero Heavy Dependencies:** Written using core POSIX utilities (`awk`, `find`, `tar`, `systemd`, `ssh`).

---

### Repository Architecture

```text
bash-utils/
├── scripts/
│   ├── backup.sh        # Directory archiver with remote dispatch (AWS S3 / FTP)
│   ├── cleanup_logs.sh  # Time-based log rotation and retention cleaner
│   ├── deploy_app.sh    # Remote application synchronizer and systemd orchestrator
│   ├── monitor.sh       # Continuous resource telemetry (CPU/RAM/Disk) with alerting
│   ├── test_scripts.sh  # Automated regression and syntax validation runner
│   └── utils.sh         # Shared library (logging, styling, command verification)
└── README.md
```

---

### Utilities Reference

#### 1. Backup Orchestrator (`backup.sh`)
Compresses target directories into timestamped tarballs, validates integrity, and streams them to AWS S3 or remote FTP endpoints.

```bash
# Upload to an S3 bucket with a 14-day retention tag
./scripts/backup.sh --source /var/www/app --dest s3://my-cloud-backups/production/ --retention 14

# Stream to an FTP server
./scripts/backup.sh --source /etc/nginx --dest ftp://backupuser:secret@storage.corp.internal/backups/
```

#### 2. Log Retention Purge (`cleanup_logs.sh`)
Traverses directory trees using null-delimited find buffers to safely delete files exceeding a specific age threshold.

```bash
# Purge logs older than 45 days
./scripts/cleanup_logs.sh --dir /var/log/nginx --days 45
```

#### 3. Remote Deployment Agent (`deploy_app.sh`)
Connects via SSH, handles git branch synchronization in `/opt/<service>`, and safely restarts the target systemd service.

```bash
./scripts/deploy_app.sh \
  --repo https://github.com/organization/api-gateway.git \
  --service api-gateway \
  --host deploy@10.0.1.50 \
  --branch main
```

#### 4. Real-Time Telemetry Monitor (`monitor.sh`)
Collects live CPU, memory, and root filesystem metrics using pure `awk` calculation. Dispatches webhook alerts when thresholds are breached.

```bash
# Monitor every 30 seconds, alert Slack if CPU >= 85%
./scripts/monitor.sh \
  --interval 30 \
  --threshold 85 \
  --slack-webhook "https://hooks.slack.com/services/T00/B00/XXXX"
```

---

### Automated Testing

A dedicated test runner verifies script syntax, parameter validation, and expected exit codes:

```bash
chmod +x scripts/*.sh
./scripts/test_scripts.sh
```

#### Exit Codes Matrix

| Code | Meaning |
| :--- | :--- |
| `0` | Successful execution / clean exit |
| `1` | Parameter validation failure or `--help` request |
| `2` | Path or directory does not exist |
| `3` | Required binary dependency missing (`aws`, `curl`, `ssh`) |

---

### License

Distributed under the MIT License. Developed and maintained by [Brandon Mendieta](https://github.com/NeoScraids).
