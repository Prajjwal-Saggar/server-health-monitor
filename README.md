# Server Health Monitor

A lightweight Bash script that checks the vital signs of a Linux server — disk, RAM, CPU, network, and critical services — and flags anything that crosses a configurable threshold. Every check is also written to a timestamped log file, and the script exits with a status code reflecting overall health, so it can be wired into cron, monitoring tools, or CI pipelines later.

No external dependencies, no daemon. Just `bash server-health.sh` and you get a straight answer — on screen and in the log.

## Why I built this

I kept SSH-ing into my own machine and running the same five commands over and over — `df -h`, `free`, `top`, a ping, a couple of `systemctl status` checks — just to answer "is everything okay?" This script is that five-minute ritual compressed into one command. Logging came next, once I realized a point-in-time check isn't useful if you can't look back at what happened an hour or a day ago.

## What it checks

- **Disk usage** — root partition usage via `df -h`, flagged against a threshold
- **RAM usage** — total vs. used memory from `free`, calculated as a percentage
- **CPU usage** — derived from `top`'s idle percentage (`100 - idle`)
- **Network connectivity** — a single ping to confirm the box is actually online
- **Service status** — checks whether `docker`, `ssh`, `cron`, and `rsyslog` are active via `systemctl is-active`

Each metric prints a clear `WARNING` line if it crosses its threshold, or confirms it's normal if not — and every line is mirrored to the log file with a timestamp.

## Logging & exit codes

Every run appends a timestamped entry for each check to `logs/server_health.log`, so you get a running history instead of just a snapshot:

```
09/12/26 14:32 | Server Health Checkup Started
09/12/26 14:32 | Hostname: prajjwal-ubuntu
09/12/26 14:32 | Disk Usage: 42%
09/12/26 14:32 | Disk usage is normal
09/12/26 14:32 | RAM Usage: 42%
09/12/26 14:32 | RAM usage is normal
09/12/26 14:32 | CPU Usage: 12.3%
09/12/26 14:32 | CPU usage is normal
09/12/26 14:32 | NETWORK CONNECTED
09/12/26 14:32 | docker: RUNNING
09/12/26 14:32 | ssh: RUNNING
09/12/26 14:32 | cron: RUNNING
09/12/26 14:32 | rsyslog: RUNNING
09/12/26 14:32 | Server Health Checkup Completed
```

The script also exits with a status code — `0` if everything's healthy, `1` if any check failed or crossed a threshold — so it can be dropped into a cron job or a CI/CD pipeline and treated as a pass/fail gate, not just something a human has to read.

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
- **Exit codes are how scripts talk to other scripts.** Adding `HEALTH_STATUS` and exiting with it (instead of always exiting `0`) is what turns this from "a script a human reads" into "a script cron or a CI pipeline can act on."
- **Appending to a log file with `>>`** while still printing to screen with `echo` meant duplicating each line — worth revisiting with a helper function that does both at once instead of writing every check twice.

## What's next

- Remote checks over SSH for multiple servers from one place
- Slack/webhook alerting when a threshold is breached, instead of just relying on the log file
- Log rotation, so `server_health.log` doesn't grow unbounded over time
- A helper function to cut down the repeated `echo ... | tee -a` style duplication between screen output and logging
