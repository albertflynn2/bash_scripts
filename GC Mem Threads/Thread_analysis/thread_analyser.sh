#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 logfile.log"
    exit 1
fi

LOG_FILE="$1"
OUTPUT_FILE="analysis_output_$(date +%Y%m%d_%H%M%S).txt"

# Check if the log file exists and is readable
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' not found!"
    exit 1
fi

if [ ! -r "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' is not readable!"
    exit 1
fi

# Expected values
MAX_BLOCKED_TIME=2000  # Maximum allowed blocked time in ms
MAX_PAUSED_TIME=70000  # Maximum allowed paused time in ms

# Function to analyze blocked threads
analyze_blocked_threads() {
    echo "Blocked Threads Analysis:" >> $OUTPUT_FILE
    grep -E "SAFETYGUARD INTERNAL WARNING: Thread.*has been blocked" "$LOG_FILE" | while read -r line ; do
        blocked_time=$(echo "$line" | grep -oP '(?<=blocked for )\d+')
        if [ "$blocked_time" -gt "$MAX_BLOCKED_TIME" ]; then
            echo "$line" >> $OUTPUT_FILE
            echo "Issue: Thread blocked for $blocked_time ms, which exceeds the limit of $MAX_BLOCKED_TIME ms." >> $OUTPUT_FILE
        fi
    done
    echo "" >> $OUTPUT_FILE
}

# Function to analyze paused threads
analyze_paused_threads() {
    echo "Paused Threads Analysis:" >> $OUTPUT_FILE
    grep -E "SAFETYGUARD INTERNAL WARNING: Paused thread" "$LOG_FILE" | while read -r line ; do
        paused_time=$(echo "$line" | grep -oP '(?<=maximum interval of )\d+')
        if [ "$paused_time" -gt "$MAX_PAUSED_TIME" ]; then
            echo "$line" >> $OUTPUT_FILE
            echo "Issue: Thread paused for $paused_time ms, which exceeds the limit of $MAX_PAUSED_TIME ms." >> $OUTPUT_FILE
        fi
    done
    echo "" >> $OUTPUT_FILE
}

# Function to analyze thread dumps
analyze_thread_dumps() {
    echo "Thread Dumps Analysis:" >> $OUTPUT_FILE
    grep -E "SAFETYGUARD THREAD DUMP|Thread.*state=" "$LOG_FILE" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
}

# Function to summarize findings
summarize_findings() {
    echo "Summary of Findings:" >> $OUTPUT_FILE
    echo "Blocked Threads:" >> $OUTPUT_FILE
    grep -E "SAFETYGUARD INTERNAL WARNING: Thread.*has been blocked" "$LOG_FILE" | wc -l >> $OUTPUT_FILE
    echo "Paused Threads:" >> $OUTPUT_FILE
    grep -E "SAFETYGUARD INTERNAL WARNING: Paused thread" "$LOG_FILE" | wc -l >> $OUTPUT_FILE
    echo "Thread Dumps:" >> $OUTPUT_FILE
    grep -E "SAFETYGUARD THREAD DUMP" "$LOG_FILE" | wc -l >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
}

# Main script execution
echo "Analyzing log file: $LOG_FILE" > $OUTPUT_FILE
analyze_blocked_threads
analyze_paused_threads
analyze_thread_dumps
summarize_findings

echo "Analysis complete. Results saved to $OUTPUT_FILE"