#!/bin/bash

# Function to extract stats and timestamps from the log file
extract_stats_and_timestamps() {
    local log_file="$1"
    
    if [[ ! -f "$log_file" ]]; then
        echo "Error: File '$log_file' not found."
        exit 1
    fi

    while IFS= read -r line; do
        timestamp=$(echo "$line" | jq -r '."@timestamp"')
        message=$(echo "$line" | jq -r '.message')
        
        if [[ -n "$message" ]]; then
            duration=$(echo "$message" | grep -o 'dur([0-9]*)' | grep -o '[0-9]*')
            count=$(echo "$message" | grep -o 'cnt([0-9]*)' | grep -o '[0-9]*')
            average=$(echo "$message" | grep -o 'ave([0-9]*\.[0-9]*)' | grep -o '[0-9]*\.[0-9]*')
            max_value=$(echo "$message" | grep -o 'max([0-9]*)' | grep -o '[0-9]*')
            
            if [[ -n "$duration" && -n "$count" && -n "$average" && -n "$max_value" ]]; then
                echo "Timestamp: $timestamp, Duration: $duration, Count: $count, Average: $average, Max Value: $max_value"
            fi
        fi
    done < "$log_file"
}

# Check if the log file is provided as an argument
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

# Path to the log file
log_file="$1"

# Extract stats and timestamps
extract_stats_and_timestamps "$log_file"
