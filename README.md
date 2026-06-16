# System Backup & Monitoring Scripts

Two Bash scripts for Linux — one backs up directories, the other checks your system's health.

---

## Scripts

### 1. `backup.sh` — Directory Backup Tool

Backs up any directory on your system, with or without compression.

**What it does:**
- Prompts you for a source directory and a destination path
- Checks read permissions before proceeding
- Asks if you want to compress the backup into a `.zip` file
- Handles already-existing backups by asking if you want to replace them
- Logs every backup attempt (success or failure) to a log file

**Usage:**
```bash
bash backup.sh
```
Then follow the prompts.

**Log file:** results are saved to `~/Desktop/Testing/log.txt`

---

### 2. `monitor.sh` — System Health Check

Runs a full health check on your Linux system and prints a colored, formatted report in the terminal.

**What it checks:**
-  **Disk Space** — lists all filesystems and flags any disk above 80% usage
-  **Memory Usage** — shows RAM usage and warns if above 80%
- **Running Services** — lists all active systemd services
- **Recent Updates** — pulls recent `apt update` / `apt install` commands from your bash history

**Usage:**
```bash
bash monitor.sh
```

No arguments needed — just run it and read the report.

---

## Requirements

- Linux (Ubuntu/Debian recommended)
- `bash`, `zip`, `df`, `free`, `systemctl` — all standard on most Linux systems

---

## Notes

- `backup.sh` saves backups to `/usr/root` by default — you can change the `root` variable at the top of the script or enter a custom path when prompted
- Both scripts use colored terminal output, so run them in a terminal that supports ANSI colors
