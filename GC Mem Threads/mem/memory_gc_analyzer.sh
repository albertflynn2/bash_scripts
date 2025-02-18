#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 logfile.log"
    exit 1
fi

LOG_FILE="$1"
OUTPUT_FILE="memory_gc_analysis_$(date +%Y%m%d_%H%M%S).txt"

# Check if the log file exists and is readable
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' not found!"
    exit 1
fi

if [ ! -r "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' is not readable!"
    exit 1
fi

# Function to analyze memory usage
analyze_memory_usage() {
    echo "Memory Usage Analysis:" >> $OUTPUT_FILE
    grep -E "Memory Monitor|System Monitor|Database Storage Monitor" "$LOG_FILE" | while read -r line ; do
        echo "$line" >> $OUTPUT_FILE
        # Check for high stack sizes
        stack_size=$(echo "$line" | grep -o 'stacksize=[0-9]*' | cut -d= -f2)
        if [ -n "$stack_size" ] && [ "$stack_size" -gt 10 ]; then
            echo "Issue: High stack size detected ($stack_size)." >> $OUTPUT_FILE
        fi
    done
    echo "" >> $OUTPUT_FILE
}

# Function to analyze garbage collection logs
analyze_gc_logs() {
    echo "Garbage Collection Logs Analysis:" >> $OUTPUT_FILE
    grep -E "GC|Garbage Collection" "$LOG_FILE" | while read -r line ; do
        echo "$line" >> $OUTPUT_FILE
        # Check for long GC times
        gc_time=$(echo "$line" | grep -o 'time=[0-9]*' | cut -d= -f2)
        if [ -n "$gc_time" ] && [ "$gc_time" -gt 1000 ]; then
            echo "Issue: Long garbage collection time detected ($gc_time ms)." >> $OUTPUT_FILE
        fi
    done
    echo "" >> $OUTPUT_FILE
}

# Function to summarize findings
summarize_findings() {
    echo "Summary of Findings:" >> $OUTPUT_FILE
    echo "Memory Usage Entries:" >> $OUTPUT_FILE
    grep -E "Memory Monitor|System Monitor|Database Storage Monitor" "$LOG_FILE" | wc -l >> $OUTPUT_FILE
    echo "Garbage Collection Logs:" >> $OUTPUT_FILE
    grep -E "GC|Garbage Collection" "$LOG_FILE" | wc -l >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
}

# Main script execution
echo "Analyzing log file: $LOG_FILE" > $OUTPUT_FILE
analyze_memory_usage
analyze_gc_logs
summarize_findings

echo "Analysis complete. Results saved to $OUTPUT_FILE"