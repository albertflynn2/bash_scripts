#!/bin/bash
#Replace JAVA_PID with the actual PID of your Java process.
#Set THREAD_DUMP_DIR, HEAP_DUMP_DIR, and GC_LOG_FILE to the appropriate paths#=
#chmod +x capture_thread_dump.sh
#run ./capture_thread_dump.sh
# Configuration
JAVA_PID=1339200  # Replace with the actual PID of your Java process
THREAD_DUMP_DIR="/path/to/thread_dumps"
HEAP_DUMP_DIR="/path/to/heap_dumps"
GC_LOG_FILE="/path/to/gc.log"
CHECK_INTERVAL=300  # Check every 5 minutes

# Ensure the directories exist
mkdir -p "$THREAD_DUMP_DIR"
mkdir -p "$HEAP_DUMP_DIR"

capture_thread_dump() {
    timestamp=$(date +%Y%m%d%H%M%S)
    thread_dump_file="$THREAD_DUMP_DIR/thread_dump_$timestamp.txt"
    jstack $JAVA_PID > "$thread_dump_file"
    echo "$thread_dump_file"
}

analyze_thread_dump() {
    local thread_dump_file=$1
    blocked_threads=()
    while IFS= read -r line; do
        if [[ $line == *"BLOCKED"* ]]; then
            blocked_threads+=("$line")
            for i in {1..10}; do
                read -r next_line
                blocked_threads+=("$next_line")
            done
        fi
    done < "$thread_dump_file"
}

capture_heap_dump() {
    timestamp=$(date +%Y%m%d%H%M%S)
    heap_dump_file="$HEAP_DUMP_DIR/heap_dump_$timestamp.hprof"
    jmap -dump:live,format=b,file="$heap_dump_file" $JAVA_PID
    echo "$heap_dump_file"
}

analyze_gc_logs() {
    if [ -f "$GC_LOG_FILE" ]; then
        echo "GC Logs Analysis:"
        cat "$GC_LOG_FILE"
    else
        echo "GC log file not found."
    fi
}

alert() {
    echo "Blocked Threads Alert"
    echo "The following threads are blocked:"
    for thread_info in "${blocked_threads[@]}"; do
        echo "$thread_info"
    done
}

main() {
    while true; do
        thread_dump_file=$(capture_thread_dump)
        analyze_thread_dump "$thread_dump_file"
        if [ ${#blocked_threads[@]} -ne 0 ]; then
            alert
            capture_heap_dump
            analyze_gc_logs
        fi
        sleep $CHECK_INTERVAL
    done
}

main
