
#!/bin/bash

source config/health.conf

echo "====================="
echo "Server Health Monitor"
echo "====================="

hostname=$(hostname)

echo "Hostname: $hostname"

echo "====================="
echo "Disk Usage"
echo "====================="

disk_usage_percentage=$(df -h / | tail -1 | awk '{print $5}')

echo "Disk Usage: $disk_usage_percentage"

if [ "${disk_usage_percentage%\%}" -gt $DISK_THRESHOLD ]; then
    echo "WARNING: Disk usage is above 80%."
else
    echo "Disk usage is normal."
fi

echo "====================="
echo "RAM Usage"
echo "====================="

total_ram=$(free | head -2 | tail -1 | awk '{print $2}')
used_ram=$(free | head -2 | tail -1 | awk '{print $3}')

echo "Total RAM: $total_ram"
echo "Used RAM: $used_ram"
echo "RAM Used: $((used_ram*100/total_ram))%"

if [ $((used_ram*100/total_ram)) -gt $RAM_THRESHOLD ]; then
    echo "WARNING: RAM usage is above 80%."
else
    echo "RAM usage is normal."
fi

echo "====================="
echo "CPU Usage"
echo "====================="

idle_cpu=$(top -bn 1 | grep "%Cpu" | awk '{print $8}')
cpu_usage=$(awk "BEGIN {print 100 - $idle_cpu}")

echo "Total CPU usage: $cpu_usage%"

if awk "BEGIN {exit !($cpu_usage > $CPU_THRESHOLD)}"; then
    echo "WARNING: CPU usage is above 80%."
else
    echo "CPU usage is normal."
fi

echo "====================="
echo "INTERNET Connection"
echo "====================="

if ping google.com -c 1 > /dev/null; then
    echo "NETWORK CONNECTED"
else
    echo "NETWORK NOT CONNECTED"
fi

echo "====================="
echo "Service Status"
echo "====================="

services=("docker" "ssh" "cron" "rsyslog")

for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "$service: RUNNING"
    else
        echo "$service: NOT RUNNING"
    fi
done

echo "====================="


