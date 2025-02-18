#!/bin/bash 

# Define the target directory where you want to save the socket state logs
log_dir="/path/to/your/persistent/volume"

# Define the TCP port number you want to monitor (e.g., 5437)
port_to_monitor="1538" # Use the hexadecimal representation of the port

# Infinite loop to collect socket state information
while :; do
    awk -v port="$port_to_monitor" -v date="$(date +%H:%M:%S)" '
        BEGIN {
            print "Local - Remote"
        }
        $2 ~ port {
            local = sprintf("%d.%d.%d.%d:%d",
                "0x" substr($3, 7, 2),
                "0x" substr($3, 5, 2),
                "0x" substr($3, 3, 2),
                "0x" substr($3, 1, 2),
                "0x" substr($4, index($4, ":") + 1)
            )
            remote = sprintf("%d.%d.%d.%d:%d",
                "0x" substr($5, 7, 2),
                "0x" substr($5, 5, 2),
                "0x" substr($5, 3, 2),
                "0x" substr($5, 1, 2),
                "0x" substr($6, index($6, ":") + 1)
            )
            print date " - " local " - " remote
        }
    ' /proc/net/tcp >> "$log_dir/socket_state_$(hostname -s).log"
    
    # Sleep for 10 seconds before the next collection
    sleep 10
done

