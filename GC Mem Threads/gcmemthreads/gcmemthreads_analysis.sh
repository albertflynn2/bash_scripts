#!/bin/bash

# Load configuration file
CONFIG_FILE="log_analysis.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found!"
    exit 1
fi
source "$CONFIG_FILE"

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 logfile.log"
    exit 1
fi

LOG_FILE="$1"
OUTPUT_FILE="analysis_output_$(date +%Y%m%d_%H%M%S).txt"

# Check if the log file exists and is readable
if [ ! -r "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' not found or not readable!"
    exit 1
fi

# Initialize variables to track worst issues
worst_stack_size=0
worst_stack_size_line=""
worst_gc_time=0
worst_gc_time_line=""
worst_blocked_time=0
worst_blocked_time_line=""
worst_paused_time=0
worst_paused_time_line=""

# Function to analyze memory usage
analyze_memory_usage() {
    {
        echo "========================="
        echo "Memory Usage Analysis"
        echo "========================="
        grep -E "Memory Monitor|System Monitor|Database Storage Monitor" "$LOG_FILE" | while read -r line; do
            echo "$line"
            # Check for high stack sizes
            stack_size=$(echo "$line" | grep -o 'stacksize=[0-9]*' | cut -d= -f2)
            if [ -n "$stack_size" ] && [ "$stack_size" -gt 10 ]; then
                echo "  Issue: High stack size detected ($stack_size)."
                if [ "$stack_size" -gt "$worst_stack_size" ]; then
                    worst_stack_size="$stack_size"
                    worst_stack_size_line="$line"
                fi
            fi
        done
        echo ""
        echo "----------------------------------------"
    } >> "$OUTPUT_FILE"
}

# Function to analyze garbage collection logs
analyze_gc_logs() {
    {
        echo "=============================="
        echo "Garbage Collection Logs Analysis"
        echo "=============================="
        grep -E "GC|Garbage Collection" "$LOG_FILE" | while read -r line; do
            echo "$line"
            # Check for long GC times
            gc_time=$(echo "$line" | grep -o 'time=[0-9]*' | cut -d= -f2)
            if [ -n "$gc_time" ] && [ "$gc_time" -gt 1000 ]; then
                echo "  Issue: Long garbage collection time detected ($gc_time ms)."
                if [ "$gc_time" -gt "$worst_gc_time" ]; then
                    worst_gc_time="$gc_time"
                    worst_gc_time_line="$line"
                fi
            fi
        done
        echo ""
        echo "----------------------------------------"
    } >> "$OUTPUT_FILE"
}

# Function to analyze blocked threads
analyze_blocked_threads() {
    {
        echo "========================="
        echo "Blocked Threads Analysis"
        echo "========================="
        grep -E "SAFETYGUARD INTERNAL WARNING: Thread.*has been blocked" "$LOG_FILE" | while read -r line; do
            blocked_time=$(echo "$line" | grep -o 'blocked for [0-9]*' | cut -d' ' -f3)
            if [ -n "$blocked_time" ] && [ "$blocked_time" -gt "$MAX_BLOCKED_TIME" ]; then
                echo "$line"
                echo "  Issue: Thread blocked for $blocked_time ms, which exceeds the limit of $MAX_BLOCKED_TIME ms."
                if [ "$blocked_time" -gt "$worst_blocked_time" ]; then
                    worst_blocked_time="$blocked_time"
                    worst_blocked_time_line="$line"
                fi
            fi
        done
        echo ""
        echo "----------------------------------------"
    } >> "$OUTPUT_FILE"
}

# Function to analyze paused threads
analyze_paused_threads() {
    {
        echo "========================="
        echo "Paused Threads Analysis"
        echo "========================="
        grep -E "SAFETYGUARD INTERNAL WARNING: Paused thread" "$LOG_FILE" | while read -r line; do
            paused_time=$(echo "$line" | grep -o 'maximum interval of [0-9]*' | cut -d' ' -f4)
            if [ -n "$paused_time" ] && [ "$paused_time" -gt "$MAX_PAUSED_TIME" ]; then
                echo "$line"
                echo "  Issue: Thread paused for $paused_time ms, which exceeds the limit of $MAX_PAUSED_TIME ms."
                if [ "$paused_time" -gt "$worst_paused_time" ]; then
                    worst_paused_time="$paused_time"
                    worst_paused_time_line="$line"
                fi
            fi
        done
        echo ""
        echo "----------------------------------------"
    } >> "$OUTPUT_FILE"
}

# Function to analyze thread dumps
analyze_thread_dumps() {
    {
        echo "========================="
        echo "Thread Dumps Analysis"
        echo "========================="
        grep -E "SAFETYGUARD THREAD DUMP|Thread.*state=" "$LOG_FILE"
        echo ""
        echo "----------------------------------------"
    } >> "$OUTPUT_FILE"
}

# Function to summarize findings
summarize_findings() {
    {
        echo "========================="
        echo "Summary of Findings"
        echo "========================="
        echo "Memory Usage Entries:"
        grep -E "Memory Monitor|System Monitor|Database Storage Monitor" "$LOG_FILE" | wc -l
        echo "Garbage Collection Logs:"
        grep -E "GC|Garbage Collection" "$LOG_FILE" | wc -l
        echo "Blocked Threads:"
        grep -E "SAFETYGUARD INTERNAL WARNING: Thread.*has been blocked" "$LOG_FILE" | wc -l
        echo "Paused Threads:"
        grep -E "SAFETYGUARD INTERNAL WARNING: Paused thread" "$LOG_FILE" | wc -l
        echo "Thread Dumps:"
        grep -E "SAFETYGUARD THREAD DUMP" "$LOG_FILE" | wc -l
        echo ""
        echo "----------------------------------------"
    } >> "$OUTPUT_FILE"
}

# Function to report worst issues
report_worst_issues() {
    {
        echo "========================="
        echo "Worst Issues Summary"
        echo "========================="
        echo "Worst High Stack Size:"
        echo "$worst_stack_size_line"
        echo "Worst Long GC Time:"
        echo "$worst_gc_time_line"
        echo "Worst Blocked Thread:"
        echo "$worst_blocked_time_line"
        echo "Worst Paused Thread:"
        echo "$worst_paused_time_line"
        echo ""
        echo "----------------------------------------"
    } >> "$OUTPUT_FILE"
}

# Function to send email notification
send_email_notification() {
    mail -s "Log Analysis Report" "$EMAIL_RECIPIENT" < "$OUTPUT_FILE"
}

# Main script execution
{
    echo "Analyzing log file: $LOG_FILE"
    analyze_memory_usage
    analyze_gc_logs
    analyze_blocked_threads
    analyze_paused_threads
    analyze_thread_dumps
    summarize_findings
    report_worst_issues
    echo "Analysis complete. Results saved to $OUTPUT_FILE"
} > "$OUTPUT_FILE"

# Send email notification if enabled
if [ "$EMAIL_NOTIFICATION" = "true" ]; then
    send_email_notification
fi