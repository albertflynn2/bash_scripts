#!/bin/bash

# List of IP addresses to ping
IP_ADDRESSES=("10.242.254.4" "10.242.254.5" "10.242.254.7")

# Initialize counters
success_count=0
failure_count=0
connection_dropped_start=""

# Function to ping IP addresses
ping_ips() {
  for IP in "${IP_ADDRESSES[@]}"; do
    echo "Pinging $IP..." >> results.log
    if ping -c 4 $IP >> results.log; then
      success_count=$((success_count + 1))
      if [ -n "$connection_dropped_start" ]; then
        connection_dropped_end=$(date)
        duration=$(($(date -d "$connection_dropped_end" +%s) - $(date -d "$connection_dropped_start" +%s)))
        echo "Connection to $IP restored at $connection_dropped_end after $duration seconds" >> results.log
        connection_dropped_start=""
      fi
    else
      failure_count=$((failure_count + 1))
      echo "Ping to $IP failed at $(date)" >> results.log
      if [ -z "$connection_dropped_start" ]; then
        connection_dropped_start=$(date)
      fi
    fi
  done
}

# Function to check network status
check_network() {
  for IP in "${IP_ADDRESSES[@]}"; do
    echo "Checking network status for $IP..." >> results.log
    if curl -I $IP >> results.log; then
      success_count=$((success_count + 1))
      if [ -n "$connection_dropped_start" ]; then
        connection_dropped_end=$(date)
        duration=$(($(date -d "$connection_dropped_end" +%s) - $(date -d "$connection_dropped_start" +%s)))
        echo "Connection to $IP restored at $connection_dropped_end after $duration seconds" >> results.log
        connection_dropped_start=""
      fi
    else
      failure_count=$((failure_count + 1))
      echo "Network check for $IP failed at $(date)" >> results.log
      if [ -z "$connection_dropped_start" ]; then
        connection_dropped_start=$(date)
      fi
    fi
  done
}

# Infinite loop to continuously check
while true; do
  ping_ips
  check_network
  echo "Success count: $success_count, Failure count: $failure_count" >> results.log
  sleep 60 # Wait for 60 seconds before next check
done