#!/bin/bash

source config/health.conf

LOG_FILE="logs/server_health.log"

HEALTH_STATUS=0

echo "$(date "+%D %R") | Server Health Checkup Started" >> "$LOG_FILE"

echo "====================="
echo "Server Health Monitor"
echo "====================="

hostname=$(hostname)

echo "Hostname: $hostname"
echo "$(date "+%D %R") | Hostname: $hostname" >> "$LOG_FILE"

echo "====================="
echo "Disk Usage"
echo "====================="

disk_usage_percentage=$(df -h / | tail -1 | awk '{print $5}')

echo "Disk Usage: $disk_usage_percentage"
echo "$(date "+%D %R") | Disk Usage: $disk_usage_percentage" >> "$LOG_FILE"

if [ "${disk_usage_percentage%\%}" -gt $DISK_THRESHOLD ]; then
    echo "WARNING: Disk usage is above 80%."
    echo "$(date "+%D %R") | WARNING: Disk usage is above $DISK_THRESHOLD%" >> "$LOG_FILE"
    HEALTH_STATUS=1
else
    echo "Disk usage is normal."
    echo "$(date "+%D %R") | Disk usage is normal" >> "$LOG_FILE"
fi

echo "====================="
echo "RAM Usage"
echo "====================="

total_ram=$(free | head -2 | tail -1 | awk '{print $2}')
used_ram=$(free | head -2 | tail -1 | awk '{print $3}')

ram_used_percentage=$((used_ram * 100 / total_ram))

echo "Total RAM: $total_ram"
echo "Used RAM: $used_ram"
echo "RAM Used: $ram_used_percentage%"

echo "$(date "+%D %R") | RAM Usage: $ram_used_percentage%" >> "$LOG_FILE"

if [ "$ram_used_percentage" -gt "$RAM_THRESHOLD" ]; then
    echo "WARNING: RAM usage is above 80%."
    echo "$(date "+%D %R") | WARNING: RAM usage is above $RAM_THRESHOLD%" >> "$LOG_FILE"
    HEALTH_STATUS=1
else
    echo "RAM usage is normal."
    echo "$(date "+%D %R") | RAM usage is normal" >> "$LOG_FILE"
fi

echo "====================="
echo "CPU Usage"
echo "====================="

idle_cpu=$(top -bn 1 | grep "%Cpu" | awk '{print $8}')
cpu_usage=$(awk "BEGIN {print 100 - $idle_cpu}")

echo "Total CPU usage: $cpu_usage%"

echo "$(date "+%D %R") | CPU Usage: $cpu_usage%" >> "$LOG_FILE"

if awk "BEGIN {exit !($cpu_usage > $CPU_THRESHOLD)}"; then
    echo "WARNING: CPU usage is above 80%."
    echo "$(date "+%D %R") | WARNING: CPU usage is above $CPU_THRESHOLD%" >> "$LOG_FILE"
    HEALTH_STATUS=1
else
    echo "CPU usage is normal."
    echo "$(date "+%D %R") | CPU usage is normal" >> "$LOG_FILE"
fi

echo "====================="
echo "INTERNET Connection"
echo "====================="

if ping google.com -c 1 > /dev/null; then
    echo "NETWORK CONNECTED"
    echo "$(date "+%D %R") | NETWORK CONNECTED" >> "$LOG_FILE"
else
    echo "NETWORK NOT CONNECTED"
    echo "$(date "+%D %R") | NETWORK NOT CONNECTED" >> "$LOG_FILE"
    HEALTH_STATUS=1
fi

echo "====================="
echo "Docker Service Check"
echo "====================="

if systemctl is-active --quiet docker; then
    echo "Docker: Running"
    echo "$(date "+%D %R") | Docker: Running" >> "$LOG_FILE"
else
    echo "Docker: Not Running"
    echo "$(date "+%D %R") | Docker: Not Running" >> "$LOG_FILE"
    HEALTH_STATUS=1
fi

echo "====================="
echo "Service Status"
echo "====================="

services=("docker" "ssh" "cron" "rsyslog")

for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "$service: RUNNING"
        echo "$(date "+%D %R") | $service: RUNNING" >> "$LOG_FILE"
    else
        echo "$service: NOT RUNNING"
        echo "$(date "+%D %R") | $service: NOT RUNNING" >> "$LOG_FILE"
        HEALTH_STATUS=1
    fi
done

echo "====================="

echo "$(date "+%D %R") | Server Health Checkup Completed" >> "$LOG_FILE"

exit $HEALTH_STATUS
