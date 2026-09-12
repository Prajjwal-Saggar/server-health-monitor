# Server Health Monitor

A lightweight Bash script that checks the vital signs of a Linux server — disk, RAM, CPU, network, and critical services — and flags anything that crosses a configurable threshold.

No dependencies, no dashboard, no daemon. Just `bash server-health.sh` and you get a straight answer.

## Why I built this

I kept SSH-ing into my own machine and running the same five commands over and over — `df -h`, `free`, `top`, a ping, a couple of `systemctl status` checks — just to answer "is everything okay?" This script is that five-minute ritual compressed into one command.

## What it checks

- **Disk usage** — root partition usage via `df -h`, flagged against a threshold
- **RAM usage** — total vs. used memory from `free`, calculated as a percentage
- **CPU usage** — derived from `top`'s idle percentage (`100 - idle`)
- **Network connectivity** — a single ping to confirm the box is actually online
- **Service status** — checks whether `docker`, `ssh`, `cron`, and `rsyslog` are active via `systemctl is-active`

Each metric prints a clear `WARNING` line if it crosses its threshold, or confirms it's normal if not.

## Sample output

```
=====================
Server Health Monitor
=====================
Hostname: prajjwal-ubuntu
=====================
Disk Usage
=====================
Disk Usage: 42%
Disk usage is normal.
=====================
RAM Usage
=====================
Total RAM: 8127384
Used RAM: 3456120
RAM Used: 42%
RAM usage is normal.
=====================
CPU Usage
=====================
Total CPU usage: 12.3%
CPU usage is normal.
=====================
INTERNET Connection
=====================
NETWORK CONNECTED
=====================
Service Status
=====================
docker: RUNNING
ssh: RUNNING
cron: RUNNING
rsyslog: RUNNING
=====================
```

## Configuration

Thresholds live in `config/health.conf` and are sourced at runtime, so nothing's hardcoded in the script itself:

```bash
DISK_THRESHOLD=80
RAM_THRESHOLD=80
CPU_THRESHOLD=80
```

Change the numbers, re-run the script — no code edits needed.

## Usage

```bash
git clone <this-repo>
cd server-health-monitor
chmod +x server-health.sh
./server-health.sh
```

## What I learned building this

- **Parsing command output is finicky.** `df`, `free`, and `top` all format their output slightly differently, and getting clean numbers out of them with `awk` (without hardcoding column positions that break on a different system) took more trial and error than I expected.
- **Bash doesn't do floating-point math natively** — the CPU percentage calculation needed `awk "BEGIN {...}"` since Bash's arithmetic only handles integers.
- **Sourcing a config file** (`source config/health.conf`) is a simple, clean way to separate configuration from logic, and it's a pattern I now default to instead of hardcoding values.
- **`systemctl is-active --quiet`** is a much cleaner way to check service state in a script than parsing the full `systemctl status` output.

## What's next

Right now this only checks the local machine it's run on. Planned next steps:
- Remote checks over SSH for multiple servers from one place
- Optional logging to a file with timestamps, so I can track trends instead of just a point-in-time snapshot
- Slack/webhook alerting when a threshold is breached, instead of just printing to the terminal


