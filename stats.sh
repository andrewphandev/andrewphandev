#!/bin/bash

# Determine the operating system
os=$(uname -s)

# Get System Information
echo -e "\n🔧 Info System\n---------------------"

# Linux (Ubuntu) specific commands
if [[ "$os" == "Linux" ]]; then
    kernel=$(uname -r)
    hostname=$(hostname)
    ip_private=$(hostname -I | awk '{print $1}')
    ip_public=$(curl -s https://api.ipify.org)
    cpu_model=$(lscpu | grep 'Model name' | awk -F ':' '{print $2}' | sed 's/^ *//')
    cores=$(nproc)
    total_ram=$(free -h | awk '/Mem:/ {print $2}')
    used_ram=$(free -h | awk '/Mem:/ {print $3}')
# macOS specific commands
elif [[ "$os" == "Darwin" ]]; then
    kernel=$(uname -r)
    hostname=$(hostname)
    ip_private=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')
    ip_public=$(curl -s https://api.ipify.org)
    cpu_model=$(sysctl -n machdep.cpu.brand_string)
    cores=$(sysctl -n hw.physicalcpu)
    total_ram=$(sysctl -n hw.memsize)
    used_ram=$(top -l 1 | grep "PhysMem" | awk '{print $2}')
# Windows specific commands (for Git Bash or WSL)
elif [[ "$os" == "CYGWIN"* || "$os" == "MINGW"* || "$os" == "MSYS"* ]]; then
    kernel=$(wmic os get caption)
    hostname=$(hostname)
    ip_private=$(ipconfig | grep "IPv4" | awk '{print $14}' | head -n 1)
    ip_public=$(curl -s https://api.ipify.org)
    cpu_model=$(wmic cpu get caption)
    cores=$(wmic cpu get NumberOfCores)
    total_ram=$(wmic memorychip get capacity | awk 'NR==2 {print $1/1024/1024/1024 " GB"}')
    used_ram=$(wmic os get freephysicalmemory | awk 'NR==2 {print $1/1024 " MB"}')
fi

# Print system information
echo "Hostname: $hostname"
echo "Private IP: $ip_private"
echo "Public IP: $ip_public"
echo "OS: $os"
echo "Kernel: $kernel"
echo "CPU: $cpu_model ($cores cores)"
echo "Total RAM: $total_ram"

# Info Usage
echo -e "\n📊 Info Usage\n---------------------"

# Get memory usage
if [[ "$os" == "Darwin" ]]; then
    # Use `top` command on macOS to get memory usage percentage
    mem_percent=$(top -l 1 | grep "PhysMem" | awk '{print $2}' | sed 's/[^0-9]*//g')
else
    # Linux and Windows use `free`
    mem_percent=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
fi

# Swap usage on macOS (using sysctl for swap info)
if [[ "$os" == "Darwin" ]]; then
    swap_info=$(sysctl -n vm.swapusage)
    swap_used=$(echo "$swap_info" | awk '{print $3}' | sed 's/M//')  # Get used swap (in MB)
    swap_total=$(echo "$swap_info" | awk '{print $1}' | sed 's/M//')  # Get total swap (in MB)
    if [[ "$swap_total" -gt 0 ]]; then
        swap_percent=$(echo "scale=2; $swap_used / $swap_total * 100" | bc)
    else
        swap_percent=0
    fi
elif [[ "$os" == "Linux" ]]; then
    swap_percent=$(free | awk '/Swap:/ { if ($2 == 0) { print 0 } else { printf "%.0f", $3/$2 * 100 } }')
else
    swap_percent="N/A"  # Swap is not applicable on Windows
fi

# CPU usage: on Ubuntu, use `mpstat` or `top`
if [[ "$os" == "Linux" ]]; then
    cpu=$(mpstat 1 1 | grep "Average" | awk '{print 100 - $12 "%"}')  # Calculate CPU usage on Ubuntu
elif [[ "$os" == "CYGWIN"* || "$os" == "MINGW"* || "$os" == "MSYS"* ]]; then
    cpu=$(wmic cpu get loadpercentage | tail -n 1 | sed 's/ //g')  # Get CPU load percentage on Windows
    if [[ -z "$cpu" ]]; then
        cpu="N/A"  # If no value is returned, set as N/A
    fi
else
    # macOS: Use `top -l 1` to get CPU usage percentage
    cpu=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
fi

# Get number of processes
if [[ "$os" == "Darwin" ]]; then
    processes=$(ps aux | wc -l)
else
    processes=$(ps -e | wc -l)
fi

# Uptime command (fixed for macOS)
if [[ "$os" == "Darwin" ]]; then
    uptime=$(uptime | awk '{print $3, $4, $5}')
else
    uptime=$(uptime -p)
fi

# Get current time
time=$(date)

# Storage usage: using df command to get disk information
disk_usage=$(df -h / | awk 'NR==2 {print $3 " of " $2 " (" $5 " used)"}')
disk_total=$(df -k / | awk 'NR==2 {print $2 / 1024 / 1024 " GB"}')  # Total storage
disk_used=$(df -k / | awk 'NR==2 {print $3 / 1024 / 1024 " GB"}')   # Used storage
disk_percent=$(df -h / | awk 'NR==2 {print $5}')  # Used percentage

# Output system statistics
echo "Storage usage: $disk_percent (used $disk_used of $disk_total)"
echo "Memory usage: ${mem_percent}% (used $used_ram of $total_ram)"
echo "Swap usage: ${swap_percent}%"
echo "CPU Usage: ${cpu}%"
echo "Processes: $processes"
echo "Uptime: $uptime"
echo "Time: $time"
