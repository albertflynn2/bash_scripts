#!/bin/bash

# Define the target directory where you want to save the netstat logs
log_dir="/path/to/your/persistent/volume"

# Define the TCP port number you want to monitor (e.g., 5437)
port_to_monitor="5437"

# Infinite loop to collect netstat information
while :; do
    # Use netstat to get socket state information for the specified port
    netstat -ntpo | grep ":$port_to_monitor" | while read s; do
        echo "$(date +%H:%M:%S): $s"
    done
    
    # Save the collected information to a log file
    log_file="$log_dir/netstat_$(hostname -s).log"
    cat >>"$log_file"
    
    # Sleep for 10 seconds before the next collection
    sleep 10
done
